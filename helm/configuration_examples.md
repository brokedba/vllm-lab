# Helm Production Values for vLLM Stack
## I. Core Components Configuration
### 1. Serving Engine Specification
```yaml
servingEngineSpec:
  enableEngine: true
  # Image configuration
  repository: "vllm/vllm-openai"
  tag: "v0.4.2"
  imagePullPolicy: "IfNotPresent"
  
  # Network configuration
  containerPort: 8000
  servicePort: 8000
  
  # Resource management
  resources:
    requests:
      cpu: "2"
      memory: "8Gi"
    limits:
      cpu: "4"
      memory: "16Gi"
  
  # Health checks
  livenessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
    
  startupProbe:
    initialDelaySeconds: 60
    periodSeconds: 30
    timeoutSeconds: 10
    failureThreshold: 10
  
  # Security context
  containerSecurityContext:
    runAsNonRoot: true
    runAsUser: 1000
    allowPrivilegeEscalation: false
    
  securityContext:
    fsGroup: 1000
    runAsUser: 1000
  
  # Scheduling
  runtimeClassName: "nvidia"
  schedulerName: "default-scheduler"
  tolerations:
    - key: "nvidia.com/gpu"
      operator: "Equal"
      value: "true"
      effect: "NoSchedule"
  
  # Pod disruption budget
  maxUnavailablePodDisruptionBudget: 1
  
  # Model specifications
  modelSpec:
    - name: "llama-2-7b-chat"
      modelPath: "/models/llama-2-7b-chat"
      maxModelLen: 4096
      
  # Additional configurations
  configs:
    CUDA_VISIBLE_DEVICES: "0"
    VLLM_WORKER_MULTIPROC_METHOD: "spawn"
    
  # API security
  vllmApiKey: "your-api-key-here"
  
  # Extra ports for metrics, etc.
  extraPorts:
    - name: "metrics"
      containerPort: 8080
      protocol: "TCP"
  
  # Labels for service discovery
  labels:
    app: "vllm-engine"
    version: "v1"
```
### 2. Router Specification

```yaml
routerSpec:
  enableRouter: true
  replicaCount: 2
  
  # Image configuration
  repository: "lmcache/lmstack-router"
  tag: "latest"
  imagePullPolicy: "Always"
  
  # Network configuration
  containerPort: 8080
  servicePort: 80
  serviceType: "ClusterIP"
  
  # Resource management
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1"
      memory: "2Gi"
  
  # Router-specific configuration
  routingLogic: "round_robin"
  serviceDiscovery: "k8s"
  sessionKey: "your-session-key"
  engineScrapeInterval: "30s"
  requestStatsWindow: "300s"
  lmcacheControllerPort: 9090
  
  # For static service discovery (alternative to k8s)
  # staticBackends: "http://engine1:8000,http://engine2:8000"
  # staticModels: "llama-2-7b-chat,gpt-3.5-turbo"
  
  # Authentication
  hf_token: "your-huggingface-token"
  vllmApiKey: "your-api-key-here"
  
  # Additional arguments
  extraArgs:
    - "--log-level=info"
    - "--enable-metrics"
  
  # Node selection
  nodeSelectorTerms:
    - matchExpressions:
      - key: "node-type"
        operator: "In"
        values: ["cpu-optimized"]
  
  # Labels
  labels:
    app: "vllm-router"
    component: "load-balancer"
  
  # Ingress configuration
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: "/"
      nginx.ingress.kubernetes.io/ssl-redirect: "true"
    hosts:
      - host: "vllm.example.com"
        paths:
          - path: "/"
            pathType: "Prefix"
    tls:
      - secretName: "vllm-tls"
        hosts:
          - "vllm.example.com"
  
  # Deployment strategy
  strategy:
    type: "RollingUpdate"
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
```
### 3. Cache Server Specification
```yaml
cacheserverSpec:
  enabled: true
  
  # Image configuration
  repository: "lmcache/lmstack-cache"
  tag: "latest"
  imagePullPolicy: "Always"
  
  # Network configuration
  containerPort: 8081
  servicePort: 8081
  
  # Resource management
  resources:
    requests:
      cpu: "500m"
      memory: "2Gi"
    limits:
      cpu: "1"
      memory: "4Gi"
  
  # Health checks
  livenessProbe:
    initialDelaySeconds: 30
    periodSeconds: 10
    timeoutSeconds: 5
    failureThreshold: 3
  
  # Serialization format
  serde: "json"
  
  # Node selection
  nodeSelectorTerms:
    - matchExpressions:
      - key: "storage-type"
        operator: "In"
        values: ["ssd"]
  
  # Labels
  labels:
    app: "vllm-cache"
    component: "cache-server"
```
### 4. Shared Storage Configuration
```yaml
sharedStorage:
  enabled: true
  size: "100Gi"
  storageClass: "fast-ssd"
  accessModes:
    - "ReadWriteMany"
  
  # For NFS storage
  nfs:
    server: "nfs.example.com"
    path: "/exports/vllm-models"
  
  # For hostPath (development only)
  # hostPath: "/data/vllm-models"
```
### 5. LoRA Controller (Optional)
```yaml
loraController:
  enabled: false
  # Additional LoRA-specific configurations would go here
```
# Production-Ready Strategy Configurations
### 1. Engine Strategy
```yaml
engineStrategy:
  type: "RollingUpdate"
  rollingUpdate:
    maxUnavailable: 0
    maxSurge: 1
```
### 2. Router Strategy
```yaml
routerStrategy:
  type: "RollingUpdate"
  rollingUpdate:
    maxUnavailable: 1
    maxSurge: 1
```

## Complete Production Example

See [values-production.yaml](./values-production.yaml) example.
