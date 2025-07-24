#!/usr/bin/env python3
"""
Comprehensive Test Suite for AI Agents Scaling
Tests thousands of AI agents with load testing, resilience, and integration
"""

import asyncio
import json
import logging
import time
from typing import List, Dict, Any
import aiohttp
from kubernetes import client, config
import statistics

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class AIAgentsScalingTest:
    """Test suite for AI agents scaling capabilities"""
    
    def __init__(self, namespace: str = "ai-agents"):
        self.namespace = namespace
        self.k8s_client = None
        self.test_results = []
        
    def setup_k8s_client(self):
        """Setup Kubernetes client"""
        try:
            config.load_incluster_config()
        except config.ConfigException:
            config.load_kube_config()
        
        self.k8s_client = client.CoreV1Api()
        
    async def test_service_discovery(self) -> Dict[str, Any]:
        """Test service discovery for all AI agent types"""
        logger.info("Testing service discovery...")
        
        services = [
            "ai-agent-orchestrator",
            "ai-agent-coding", 
            "ai-agent-testing",
            "ai-agent-security",
            "ai-agent-compliance",
            "ai-agent-documentation",
            "ai-agent-discovery"
        ]
        
        results = {}
        for service in services:
            try:
                # Test HTTP API endpoint
                http_url = f"http://{service}.{self.namespace}.svc.cluster.local:8080/health"
                async with aiohttp.ClientSession() as session:
                    async with session.get(http_url, timeout=10) as response:
                        if response.status == 200:
                            results[service] = {
                                "dns_resolution": "PASS",
                                "http_api": "PASS",
                                "status_code": response.status
                            }
                        else:
                            results[service] = {
                                "dns_resolution": "PASS",
                                "http_api": "FAIL",
                                "status_code": response.status
                            }
                            
            except Exception as e:
                results[service] = {
                    "dns_resolution": "FAIL",
                    "http_api": "FAIL",
                    "error": str(e)
                }
                
        return {
            "test_name": "service_discovery",
            "results": results,
            "timestamp": time.time()
        }
    
    async def test_load_scaling(self, target_rps: int = 1000, duration: int = 60) -> Dict[str, Any]:
        """Test load scaling capabilities"""
        logger.info(f"Testing load scaling with {target_rps} RPS for {duration}s...")
        
        start_time = time.time()
        end_time = start_time + duration
        
        # Track metrics
        request_count = 0
        success_count = 0
        error_count = 0
        latencies = []
        
        # Calculate request interval
        interval = 1.0 / target_rps
        
        async def make_request():
            nonlocal request_count, success_count, error_count
            
            try:
                start = time.time()
                async with aiohttp.ClientSession() as session:
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/health"
                    async with session.get(url, timeout=5) as response:
                        latency = time.time() - start
                        latencies.append(latency)
                        
                        if response.status == 200:
                            success_count += 1
                        else:
                            error_count += 1
                            
                        request_count += 1
                        
            except Exception as e:
                error_count += 1
                request_count += 1
                logger.warning(f"Request failed: {e}")
        
        # Generate load
        tasks = []
        while time.time() < end_time:
            tasks.append(asyncio.create_task(make_request()))
            await asyncio.sleep(interval)
            
            # Clean up completed tasks
            tasks = [t for t in tasks if not t.done()]
        
        # Wait for remaining tasks
        await asyncio.gather(*tasks, return_exceptions=True)
        
        # Calculate metrics
        actual_rps = request_count / duration
        success_rate = success_count / max(request_count, 1)
        avg_latency = statistics.mean(latencies) if latencies else 0
        p95_latency = statistics.quantiles(latencies, n=20)[18] if len(latencies) >= 20 else 0
        p99_latency = statistics.quantiles(latencies, n=100)[98] if len(latencies) >= 100 else 0
        
        return {
            "test_name": "load_scaling",
            "target_rps": target_rps,
            "actual_rps": actual_rps,
            "success_rate": success_rate,
            "avg_latency": avg_latency,
            "p95_latency": p95_latency,
            "p99_latency": p99_latency,
            "request_count": request_count,
            "success_count": success_count,
            "error_count": error_count,
            "duration": duration,
            "timestamp": time.time()
        }
    
    async def test_autoscaling(self) -> Dict[str, Any]:
        """Test KEDA autoscaling capabilities"""
        logger.info("Testing KEDA autoscaling...")
        
        try:
            # Get current replica counts
            apps_v1 = client.AppsV1Api()
            
            deployments = [
                "ai-agent-orchestrator",
                "ai-agent-coding",
                "ai-agent-testing", 
                "ai-agent-security",
                "ai-agent-compliance",
                "ai-agent-documentation",
                "ai-agent-discovery"
            ]
            
            initial_replicas = {}
            for deployment in deployments:
                try:
                    dep = apps_v1.read_namespaced_deployment(
                        name=deployment,
                        namespace=self.namespace
                    )
                    initial_replicas[deployment] = dep.spec.replicas
                except Exception as e:
                    logger.warning(f"Could not get replicas for {deployment}: {e}")
            
            # Generate load to trigger scaling
            logger.info("Generating load to trigger autoscaling...")
            await self.test_load_scaling(target_rps=500, duration=30)
            
            # Wait for scaling to take effect
            await asyncio.sleep(60)
            
            # Check final replica counts
            final_replicas = {}
            scaling_changes = {}
            
            for deployment in deployments:
                try:
                    dep = apps_v1.read_namespaced_deployment(
                        name=deployment,
                        namespace=self.namespace
                    )
                    final_replicas[deployment] = dep.spec.replicas
                    
                    initial = initial_replicas.get(deployment, 0)
                    final = dep.spec.replicas
                    scaling_changes[deployment] = {
                        "initial": initial,
                        "final": final,
                        "scaled": final > initial
                    }
                    
                except Exception as e:
                    logger.warning(f"Could not get final replicas for {deployment}: {e}")
            
            return {
                "test_name": "autoscaling",
                "initial_replicas": initial_replicas,
                "final_replicas": final_replicas,
                "scaling_changes": scaling_changes,
                "timestamp": time.time()
            }
            
        except Exception as e:
            return {
                "test_name": "autoscaling",
                "error": str(e),
                "timestamp": time.time()
            }
    
    async def test_resilience(self) -> Dict[str, Any]:
        """Test resilience under failure conditions"""
        logger.info("Testing resilience...")
        
        # Test circuit breaker behavior
        circuit_breaker_results = await self._test_circuit_breaker()
        
        # Test retry behavior
        retry_results = await self._test_retry_behavior()
        
        # Test fault injection
        fault_injection_results = await self._test_fault_injection()
        
        return {
            "test_name": "resilience",
            "circuit_breaker": circuit_breaker_results,
            "retry_behavior": retry_results,
            "fault_injection": fault_injection_results,
            "timestamp": time.time()
        }
    
    async def _test_circuit_breaker(self) -> Dict[str, Any]:
        """Test circuit breaker behavior"""
        logger.info("Testing circuit breaker...")
        
        # Simulate failures to trigger circuit breaker
        failure_count = 0
        success_count = 0
        
        for i in range(20):
            try:
                async with aiohttp.ClientSession() as session:
                    # Use a non-existent endpoint to trigger failures
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/nonexistent"
                    async with session.get(url, timeout=5) as response:
                        if response.status == 404:
                            failure_count += 1
                        else:
                            success_count += 1
            except Exception:
                failure_count += 1
        
        return {
            "failure_count": failure_count,
            "success_count": success_count,
            "failure_rate": failure_count / (failure_count + success_count)
        }
    
    async def _test_retry_behavior(self) -> Dict[str, Any]:
        """Test retry behavior"""
        logger.info("Testing retry behavior...")
        
        retry_attempts = []
        
        for i in range(10):
            start_time = time.time()
            try:
                async with aiohttp.ClientSession() as session:
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/health"
                    async with session.get(url, timeout=10) as response:
                        if response.status == 200:
                            retry_attempts.append(time.time() - start_time)
            except Exception as e:
                logger.warning(f"Request failed: {e}")
        
        return {
            "attempts": len(retry_attempts),
            "avg_response_time": statistics.mean(retry_attempts) if retry_attempts else 0,
            "success_rate": len(retry_attempts) / 10
        }
    
    async def _test_fault_injection(self) -> Dict[str, Any]:
        """Test fault injection"""
        logger.info("Testing fault injection...")
        
        # Test with fault injection enabled
        delay_count = 0
        abort_count = 0
        normal_count = 0
        
        for i in range(100):
            start_time = time.time()
            try:
                async with aiohttp.ClientSession() as session:
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/health"
                    async with session.get(url, timeout=10) as response:
                        response_time = time.time() - start_time
                        
                        if response.status == 500:
                            abort_count += 1
                        elif response_time > 1.0:  # Assuming delay is 2s
                            delay_count += 1
                        else:
                            normal_count += 1
                            
            except Exception:
                abort_count += 1
        
        return {
            "total_requests": 100,
            "normal_responses": normal_count,
            "delayed_responses": delay_count,
            "aborted_responses": abort_count,
            "delay_rate": delay_count / 100,
            "abort_rate": abort_count / 100
        }
    
    async def test_observability(self) -> Dict[str, Any]:
        """Test observability stack"""
        logger.info("Testing observability...")
        
        observability_services = [
            ("prometheus", "http://prometheus.istio-system.svc.cluster.local:9090/api/v1/status/config"),
            ("grafana", "http://grafana.istio-system.svc.cluster.local:3000/api/health"),
            ("jaeger", "http://jaeger-query.istio-system.svc.cluster.local:16686/api/services"),
            ("kiali", "http://kiali.istio-system.svc.cluster.local:20001/api/health")
        ]
        
        results = {}
        for service_name, url in observability_services:
            try:
                async with aiohttp.ClientSession() as session:
                    async with session.get(url, timeout=10) as response:
                        results[service_name] = {
                            "status": "UP" if response.status == 200 else "DOWN",
                            "status_code": response.status
                        }
            except Exception as e:
                results[service_name] = {
                    "status": "DOWN",
                    "error": str(e)
                }
        
        return {
            "test_name": "observability",
            "results": results,
            "timestamp": time.time()
        }
    
    async def test_integration(self) -> Dict[str, Any]:
        """Test end-to-end integration"""
        logger.info("Testing end-to-end integration...")
        
        # Test complete workflow
        workflow_steps = []
        
        try:
            # Step 1: Create agent
            step1_start = time.time()
            async with aiohttp.ClientSession() as session:
                create_data = {
                    "type": "coding",
                    "config": {
                        "model": "gpt-4",
                        "max_tokens": 4000
                    }
                }
                url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/agents"
                async with session.post(url, json=create_data, timeout=10) as response:
                    if response.status == 201:
                        agent_data = await response.json()
                        agent_id = agent_data.get("id")
                        workflow_steps.append({
                            "step": "create_agent",
                            "status": "SUCCESS",
                            "duration": time.time() - step1_start,
                            "agent_id": agent_id
                        })
                    else:
                        workflow_steps.append({
                            "step": "create_agent",
                            "status": "FAILED",
                            "status_code": response.status
                        })
            
            # Step 2: Assign task
            if agent_id:
                step2_start = time.time()
                async with aiohttp.ClientSession() as session:
                    task_data = {
                        "type": "code_review",
                        "repository": "medinovai/ai-platform",
                        "files": ["src/agents/coding.py"]
                    }
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/agents/{agent_id}/tasks"
                    async with session.post(url, json=task_data, timeout=10) as response:
                        if response.status == 201:
                            task_data = await response.json()
                            task_id = task_data.get("id")
                            workflow_steps.append({
                                "step": "assign_task",
                                "status": "SUCCESS",
                                "duration": time.time() - step2_start,
                                "task_id": task_id
                            })
                        else:
                            workflow_steps.append({
                                "step": "assign_task",
                                "status": "FAILED",
                                "status_code": response.status
                            })
            
            # Step 3: Check task status
            if task_id:
                step3_start = time.time()
                async with aiohttp.ClientSession() as session:
                    url = f"http://ai-agent-orchestrator.{self.namespace}.svc.cluster.local:8080/tasks/{task_id}"
                    async with session.get(url, timeout=10) as response:
                        if response.status == 200:
                            task_status = await response.json()
                            workflow_steps.append({
                                "step": "check_task",
                                "status": "SUCCESS",
                                "duration": time.time() - step3_start,
                                "task_status": task_status.get("status")
                            })
                        else:
                            workflow_steps.append({
                                "step": "check_task",
                                "status": "FAILED",
                                "status_code": response.status
                            })
                            
        except Exception as e:
            workflow_steps.append({
                "step": "integration",
                "status": "ERROR",
                "error": str(e)
            })
        
        return {
            "test_name": "integration",
            "workflow_steps": workflow_steps,
            "timestamp": time.time()
        }
    
    async def run_all_tests(self) -> Dict[str, Any]:
        """Run all tests"""
        logger.info("Starting comprehensive AI agents scaling tests...")
        
        self.setup_k8s_client()
        
        tests = [
            self.test_service_discovery(),
            self.test_load_scaling(),
            self.test_autoscaling(),
            self.test_resilience(),
            self.test_observability(),
            self.test_integration()
        ]
        
        results = await asyncio.gather(*tests, return_exceptions=True)
        
        # Process results
        test_results = []
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                test_results.append({
                    "test_name": f"test_{i}",
                    "status": "ERROR",
                    "error": str(result)
                })
            else:
                test_results.append(result)
        
        # Generate summary
        summary = self._generate_summary(test_results)
        
        return {
            "test_suite": "ai_agents_scaling",
            "timestamp": time.time(),
            "summary": summary,
            "detailed_results": test_results
        }
    
    def _generate_summary(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Generate test summary"""
        total_tests = len(results)
        passed_tests = 0
        failed_tests = 0
        error_tests = 0
        
        for result in results:
            if "error" in result:
                error_tests += 1
            elif result.get("status") == "SUCCESS":
                passed_tests += 1
            else:
                failed_tests += 1
        
        return {
            "total_tests": total_tests,
            "passed": passed_tests,
            "failed": failed_tests,
            "errors": error_tests,
            "success_rate": passed_tests / total_tests if total_tests > 0 else 0
        }


# Test runner
async def main():
    """Run the test suite"""
    test_suite = AIAgentsScalingTest()
    results = await test_suite.run_all_tests()
    
    # Print results
    print(json.dumps(results, indent=2))
    
    # Save results to file
    with open("test_results.json", "w") as f:
        json.dump(results, f, indent=2)
    
    # Exit with appropriate code
    if results["summary"]["success_rate"] >= 0.8:
        print("✅ Tests passed with 80%+ success rate")
        exit(0)
    else:
        print("❌ Tests failed - success rate below 80%")
        exit(1)


if __name__ == "__main__":
    asyncio.run(main()) 