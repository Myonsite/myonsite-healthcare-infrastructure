#!/usr/bin/env python3
"""
xDS-aware gRPC Client for AI Agents
Supports dynamic endpoint discovery and load balancing for thousands of AI agents
"""

import asyncio
import json
import logging
import time
from typing import Dict, List, Optional, Any
import grpc
from grpc import aio
import ai_agent_service_pb2
import ai_agent_service_pb2_grpc

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AIAgentClient:
    """
    xDS-aware gRPC client for AI agent communication
    Supports dynamic service discovery and load balancing
    """
    
    def __init__(self,
                 service_name: str = "ai-agent-orchestrator",
                 namespace: str = "ai-agents",
                 port: int = 9090,
                 use_xds: bool = True,
                 max_retries: int = 3,
                 timeout: float = 30.0):
        """
        Initialize the AI Agent client
        
        Args:
            service_name: Kubernetes service name
            namespace: Kubernetes namespace
            port: gRPC port
            use_xds: Whether to use xDS for service discovery
            max_retries: Maximum number of retries
            timeout: Request timeout in seconds
        """
        self.service_name = service_name
        self.namespace = namespace
        self.port = port
        self.use_xds = use_xds
        self.max_retries = max_retries
        self.timeout = timeout
        
        # xDS configuration
        if use_xds:
            self.target = f"xds:///{service_name}.{namespace}.svc.cluster.local:{port}"
        else:
            self.target = f"{service_name}.{namespace}.svc.cluster.local:{port}"
        
        # Connection pool
        self._channel = None
        self._stub = None
        self._lock = asyncio.Lock()
        
        # Metrics
        self.request_count = 0
        self.error_count = 0
        self.latency_sum = 0.0
        
    async def _get_channel(self) -> aio.Channel:
        """Get or create gRPC channel with xDS support"""
        if self._channel is None:
            if self.use_xds:
                # xDS-aware channel
                self._channel = aio.secure_channel(
                    self.target,
                    grpc.ssl_channel_credentials(),
                    options=[
                        ('grpc.enable_retries', 1),
                        ('grpc.keepalive_time_ms', 30000),
                        ('grpc.keepalive_timeout_ms', 5000),
                        ('grpc.keepalive_permit_without_calls', True),
                        ('grpc.http2.max_pings_without_data', 0),
                        ('grpc.http2.min_time_between_pings_ms', 10000),
                        ('grpc.http2.min_ping_interval_without_data_ms', 300000),
                    ]
                )
            else:
                # Direct connection
                self._channel = aio.insecure_channel(
                    self.target,
                    options=[
                        ('grpc.enable_retries', 1),
                        ('grpc.keepalive_time_ms', 30000),
                        ('grpc.keepalive_timeout_ms', 5000),
                        ('grpc.keepalive_permit_without_calls', True),
                    ]
                )
        return self._channel
    
    async def _get_stub(self) -> ai_agent_service_pb2_grpc.AIAgentServiceStub:
        """Get or create gRPC stub"""
        if self._stub is None:
            channel = await self._get_channel()
            self._stub = ai_agent_service_pb2_grpc.AIAgentServiceStub(channel)
        return self._stub
    
    async def _execute_with_retry(self, operation, *args, **kwargs):
        """Execute operation with retry logic"""
        last_exception = None
        
        for attempt in range(self.max_retries):
            try:
                start_time = time.time()
                result = await operation(*args, **kwargs)
                latency = time.time() - start_time
                
                # Update metrics
                self.request_count += 1
                self.latency_sum += latency
                
                logger.info(f"Request completed in {latency:.3f}s (attempt {attempt + 1})")
                return result
                
            except grpc.RpcError as e:
                last_exception = e
                self.error_count += 1
                
                if e.code() == grpc.StatusCode.UNAVAILABLE:
                    logger.warning(f"Service unavailable, retrying... (attempt {attempt + 1})")
                    await asyncio.sleep(2 ** attempt)  # Exponential backoff
                elif e.code() == grpc.StatusCode.DEADLINE_EXCEEDED:
                    logger.warning(f"Request timeout, retrying... (attempt {attempt + 1})")
                    await asyncio.sleep(1)
                else:
                    logger.error(f"gRPC error: {e.code()} - {e.details()}")
                    break
                    
        logger.error(f"All retry attempts failed: {last_exception}")
        raise last_exception
    
    async def create_agent(self, agent_type: str, config: Dict[str, Any]) -> ai_agent_service_pb2.Agent:
        """Create a new AI agent"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.CreateAgentRequest(
                type=agent_type,
                config=json.dumps(config)
            )
            return await self._execute_with_retry(stub.CreateAgent, request, timeout=self.timeout)
    
    async def get_agent(self, agent_id: str) -> ai_agent_service_pb2.Agent:
        """Get agent by ID"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.GetAgentRequest(id=agent_id)
            return await self._execute_with_retry(stub.GetAgent, request, timeout=self.timeout)
    
    async def list_agents(self, agent_type: Optional[str] = None) -> List[ai_agent_service_pb2.Agent]:
        """List all agents, optionally filtered by type"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.ListAgentsRequest()
            if agent_type:
                request.type = agent_type
            
            response = await self._execute_with_retry(stub.ListAgents, request, timeout=self.timeout)
            return list(response.agents)
    
    async def update_agent(self, agent_id: str, config: Dict[str, Any]) -> ai_agent_service_pb2.Agent:
        """Update agent configuration"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.UpdateAgentRequest(
                id=agent_id,
                config=json.dumps(config)
            )
            return await self._execute_with_retry(stub.UpdateAgent, request, timeout=self.timeout)
    
    async def delete_agent(self, agent_id: str) -> bool:
        """Delete an agent"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.DeleteAgentRequest(id=agent_id)
            response = await self._execute_with_retry(stub.DeleteAgent, request, timeout=self.timeout)
            return response.success
    
    async def register_agent(self, agent_id: str, endpoint: str) -> bool:
        """Register agent endpoint"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.RegisterAgentRequest(
                id=agent_id,
                endpoint=endpoint
            )
            response = await self._execute_with_retry(stub.RegisterAgent, request, timeout=self.timeout)
            return response.success
    
    async def deregister_agent(self, agent_id: str) -> bool:
        """Deregister agent endpoint"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.DeregisterAgentRequest(id=agent_id)
            response = await self._execute_with_retry(stub.DeregisterAgent, request, timeout=self.timeout)
            return response.success
    
    async def assign_task(self, agent_id: str, task_data: Dict[str, Any]) -> ai_agent_service_pb2.Task:
        """Assign a task to an agent"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.AssignTaskRequest(
                agent_id=agent_id,
                task_data=json.dumps(task_data)
            )
            return await self._execute_with_retry(stub.AssignTask, request, timeout=self.timeout)
    
    async def get_task(self, task_id: str) -> ai_agent_service_pb2.Task:
        """Get task by ID"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.GetTaskRequest(id=task_id)
            return await self._execute_with_retry(stub.GetTask, request, timeout=self.timeout)
    
    async def update_task(self, task_id: str, status: str, result: Optional[Dict[str, Any]] = None) -> ai_agent_service_pb2.Task:
        """Update task status and result"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.UpdateTaskRequest(
                id=task_id,
                status=status
            )
            if result:
                request.result = json.dumps(result)
            return await self._execute_with_retry(stub.UpdateTask, request, timeout=self.timeout)
    
    async def complete_task(self, task_id: str, result: Dict[str, Any]) -> ai_agent_service_pb2.Task:
        """Complete a task with result"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.CompleteTaskRequest(
                id=task_id,
                result=json.dumps(result)
            )
            return await self._execute_with_retry(stub.CompleteTask, request, timeout=self.timeout)
    
    async def cancel_task(self, task_id: str) -> bool:
        """Cancel a task"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.CancelTaskRequest(id=task_id)
            response = await self._execute_with_retry(stub.CancelTask, request, timeout=self.timeout)
            return response.success
    
    async def list_tasks(self, agent_id: Optional[str] = None, status: Optional[str] = None) -> List[ai_agent_service_pb2.Task]:
        """List tasks, optionally filtered by agent or status"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.ListTasksRequest()
            if agent_id:
                request.agent_id = agent_id
            if status:
                request.status = status
            
            response = await self._execute_with_retry(stub.ListTasks, request, timeout=self.timeout)
            return list(response.tasks)
    
    async def send_message(self, from_agent_id: str, to_agent_id: str, message: Dict[str, Any]) -> bool:
        """Send message between agents"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.SendMessageRequest(
                from_agent_id=from_agent_id,
                to_agent_id=to_agent_id,
                message=json.dumps(message)
            )
            response = await self._execute_with_retry(stub.SendMessage, request, timeout=self.timeout)
            return response.success
    
    async def receive_messages(self, agent_id: str, limit: int = 10) -> List[ai_agent_service_pb2.Message]:
        """Receive messages for an agent"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.ReceiveMessagesRequest(
                agent_id=agent_id,
                limit=limit
            )
            response = await self._execute_with_retry(stub.ReceiveMessages, request, timeout=self.timeout)
            return list(response.messages)
    
    async def broadcast_message(self, from_agent_id: str, message: Dict[str, Any], agent_types: Optional[List[str]] = None) -> bool:
        """Broadcast message to multiple agents"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.BroadcastMessageRequest(
                from_agent_id=from_agent_id,
                message=json.dumps(message)
            )
            if agent_types:
                request.agent_types.extend(agent_types)
            
            response = await self._execute_with_retry(stub.BroadcastMessage, request, timeout=self.timeout)
            return response.success
    
    async def health_check(self) -> Dict[str, Any]:
        """Perform health check"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.HealthCheckRequest()
            response = await self._execute_with_retry(stub.HealthCheck, request, timeout=self.timeout)
            return {
                "status": response.status,
                "timestamp": response.timestamp,
                "version": response.version,
                "uptime": response.uptime
            }
    
    async def get_metrics(self) -> Dict[str, Any]:
        """Get service metrics"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.GetMetricsRequest()
            response = await self._execute_with_retry(stub.GetMetrics, request, timeout=self.timeout)
            return json.loads(response.metrics)
    
    async def get_status(self) -> Dict[str, Any]:
        """Get service status"""
        async with self._lock:
            stub = await self._get_stub()
            request = ai_agent_service_pb2.GetStatusRequest()
            response = await self._execute_with_retry(stub.GetStatus, request, timeout=self.timeout)
            return {
                "status": response.status,
                "active_agents": response.active_agents,
                "total_tasks": response.total_tasks,
                "pending_tasks": response.pending_tasks,
                "completed_tasks": response.completed_tasks,
                "failed_tasks": response.failed_tasks
            }
    
    def get_client_metrics(self) -> Dict[str, Any]:
        """Get client-side metrics"""
        avg_latency = self.latency_sum / max(self.request_count, 1)
        error_rate = self.error_count / max(self.request_count, 1)
        
        return {
            "request_count": self.request_count,
            "error_count": self.error_count,
            "error_rate": error_rate,
            "average_latency": avg_latency,
            "target": self.target,
            "use_xds": self.use_xds
        }
    
    async def close(self):
        """Close the client connection"""
        if self._channel:
            await self._channel.close()
            self._channel = None
            self._stub = None

# Example usage
async def main():
    """Example usage of the AI Agent client"""
    client = AIAgentClient(
        service_name="ai-agent-orchestrator",
        namespace="ai-agents",
        use_xds=True
    )
    
    try:
        # Health check
        health = await client.health_check()
        print(f"Health check: {health}")
        
        # Create an agent
        agent_config = {
            "type": "coding",
            "model": "gpt-4",
            "max_tokens": 4000,
            "temperature": 0.7
        }
        agent = await client.create_agent("coding", agent_config)
        print(f"Created agent: {agent.id}")
        
        # Assign a task
        task_data = {
            "type": "code_review",
            "repository": "medinovai/ai-platform",
            "pull_request": 123,
            "files": ["src/agents/coding.py"]
        }
        task = await client.assign_task(agent.id, task_data)
        print(f"Assigned task: {task.id}")
        
        # Get status
        status = await client.get_status()
        print(f"Service status: {status}")
        
        # Get client metrics
        metrics = client.get_client_metrics()
        print(f"Client metrics: {metrics}")
        
    except Exception as e:
        logger.error(f"Error: {e}")
    finally:
        await client.close()

if __name__ == "__main__":
    asyncio.run(main()) 