#!/usr/bin/env python3
"""
CrewAI FastAPI Application
Multi-agent orchestration platform for MedinovAI
"""

import os
import yaml
import logging
from typing import Dict, List, Optional
from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2
from psycopg2.extras import RealDictCursor
import prometheus_client
from prometheus_client import Counter, Histogram, Gauge
import time

# Prometheus metrics
REQUEST_COUNT = Counter('crewai_requests_total', 'Total requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('crewai_request_duration_seconds', 'Request latency')
ACTIVE_AGENTS = Gauge('crewai_active_agents', 'Number of active agents')
ACTIVE_CREWS = Gauge('crewai_active_crews', 'Number of active crews')

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="CrewAI API",
    description="Multi-agent orchestration platform for MedinovAI",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class Agent(BaseModel):
    name: str
    role: str
    goal: str
    backstory: str
    verbose: bool = True
    allow_delegation: bool = False
    tools: List[str] = []

class Task(BaseModel):
    description: str
    expected_output: Optional[str] = None
    agent_id: Optional[int] = None

class Crew(BaseModel):
    name: str
    description: Optional[str] = None
    agents: List[Agent]
    tasks: List[Task]

class ProcessRequest(BaseModel):
    crew_id: int
    process_type: str = "sequential"
    verbose: bool = True
    memory: bool = True
    cache: bool = True

# Database connection
def get_db_connection():
    """Get database connection"""
    try:
        conn = psycopg2.connect(
            host=os.getenv("DATABASE_HOST", "crewai-postgresql"),
            database=os.getenv("DATABASE_NAME", "crewai"),
            user=os.getenv("DATABASE_USER", "crewai"),
            password=os.getenv("DATABASE_PASSWORD", "crewai_password"),
            cursor_factory=RealDictCursor
        )
        return conn
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
        raise HTTPException(status_code=500, detail="Database connection failed")

# Health check endpoints
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "crewai"}

@app.get("/ready")
async def readiness_check():
    """Readiness check endpoint"""
    try:
        conn = get_db_connection()
        conn.close()
        return {"status": "ready", "service": "crewai"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return prometheus_client.generate_latest()

# Agent management
@app.post("/agents", response_model=Dict)
async def create_agent(agent: Agent):
    """Create a new agent"""
    REQUEST_COUNT.labels(method="POST", endpoint="/agents").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO agents (name, role, goal, backstory, verbose, allow_delegation, tools)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
            RETURNING id
        """, (agent.name, agent.role, agent.goal, agent.backstory, 
              agent.verbose, agent.allow_delegation, agent.tools))
        
        agent_id = cursor.fetchone()['id']
        conn.commit()
        cursor.close()
        conn.close()
        
        ACTIVE_AGENTS.inc()
        return {"id": agent_id, "message": "Agent created successfully"}
        
    except Exception as e:
        logger.error(f"Failed to create agent: {e}")
        raise HTTPException(status_code=500, detail="Failed to create agent")

@app.get("/agents", response_model=List[Dict])
async def list_agents():
    """List all agents"""
    REQUEST_COUNT.labels(method="GET", endpoint="/agents").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM agents ORDER BY created_at DESC")
        agents = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return [dict(agent) for agent in agents]
        
    except Exception as e:
        logger.error(f"Failed to list agents: {e}")
        raise HTTPException(status_code=500, detail="Failed to list agents")

# Crew management
@app.post("/crews", response_model=Dict)
async def create_crew(crew: Crew):
    """Create a new crew"""
    REQUEST_COUNT.labels(method="POST", endpoint="/crews").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO crews (name, description, agents, tasks)
            VALUES (%s, %s, %s, %s)
            RETURNING id
        """, (crew.name, crew.description, 
              [agent.dict() for agent in crew.agents],
              [task.dict() for task in crew.tasks]))
        
        crew_id = cursor.fetchone()['id']
        conn.commit()
        cursor.close()
        conn.close()
        
        ACTIVE_CREWS.inc()
        return {"id": crew_id, "message": "Crew created successfully"}
        
    except Exception as e:
        logger.error(f"Failed to create crew: {e}")
        raise HTTPException(status_code=500, detail="Failed to create crew")

@app.get("/crews", response_model=List[Dict])
async def list_crews():
    """List all crews"""
    REQUEST_COUNT.labels(method="GET", endpoint="/crews").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM crews ORDER BY created_at DESC")
        crews = cursor.fetchall()
        
        cursor.close()
        conn.close()
        
        return [dict(crew) for crew in crews]
        
    except Exception as e:
        logger.error(f"Failed to list crews: {e}")
        raise HTTPException(status_code=500, detail="Failed to list crews")

# Process execution
@app.post("/process", response_model=Dict)
async def execute_process(request: ProcessRequest, background_tasks: BackgroundTasks):
    """Execute a crew process"""
    REQUEST_COUNT.labels(method="POST", endpoint="/process").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        # Get crew details
        cursor.execute("SELECT * FROM crews WHERE id = %s", (request.crew_id,))
        crew = cursor.fetchone()
        
        if not crew:
            raise HTTPException(status_code=404, detail="Crew not found")
        
        # Create process record
        cursor.execute("""
            INSERT INTO processes (crew_id, process_type, verbose, memory, cache)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
        """, (request.crew_id, request.process_type, 
              request.verbose, request.memory, request.cache))
        
        process_id = cursor.fetchone()['id']
        conn.commit()
        cursor.close()
        conn.close()
        
        # Execute process in background
        background_tasks.add_task(execute_crew_process, process_id, crew)
        
        return {
            "process_id": process_id,
            "message": "Process started",
            "status": "running"
        }
        
    except Exception as e:
        logger.error(f"Failed to execute process: {e}")
        raise HTTPException(status_code=500, detail="Failed to execute process")

async def execute_crew_process(process_id: int, crew: Dict):
    """Execute crew process in background"""
    start_time = time.time()
    
    try:
        # Simulate CrewAI process execution
        logger.info(f"Starting process {process_id} for crew {crew['name']}")
        
        # Update process status
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("""
            UPDATE processes 
            SET status = 'running', updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (process_id,))
        
        # Simulate work
        import asyncio
        await asyncio.sleep(5)  # Simulate processing time
        
        # Update with result
        result = f"Process completed successfully for crew {crew['name']}"
        cursor.execute("""
            UPDATE processes 
            SET status = 'completed', result = %s, updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
        """, (result, process_id))
        
        conn.commit()
        cursor.close()
        conn.close()
        
        duration = time.time() - start_time
        REQUEST_LATENCY.observe(duration)
        
        logger.info(f"Process {process_id} completed in {duration:.2f}s")
        
    except Exception as e:
        logger.error(f"Process {process_id} failed: {e}")
        
        # Update process status to failed
        try:
            conn = get_db_connection()
            cursor = conn.cursor()
            
            cursor.execute("""
                UPDATE processes 
                SET status = 'failed', result = %s, updated_at = CURRENT_TIMESTAMP
                WHERE id = %s
            """, (str(e), process_id))
            
            conn.commit()
            cursor.close()
            conn.close()
        except Exception as update_error:
            logger.error(f"Failed to update process status: {update_error}")

@app.get("/processes/{process_id}", response_model=Dict)
async def get_process_status(process_id: int):
    """Get process status"""
    REQUEST_COUNT.labels(method="GET", endpoint="/processes").inc()
    
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM processes WHERE id = %s", (process_id,))
        process = cursor.fetchone()
        
        cursor.close()
        conn.close()
        
        if not process:
            raise HTTPException(status_code=404, detail="Process not found")
        
        return dict(process)
        
    except Exception as e:
        logger.error(f"Failed to get process status: {e}")
        raise HTTPException(status_code=500, detail="Failed to get process status")

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "CrewAI API",
        "version": "1.0.0",
        "endpoints": {
            "agents": "/agents",
            "crews": "/crews",
            "process": "/process",
            "health": "/health",
            "metrics": "/metrics"
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 