## Intro
- Production-stack tutorials folder contains 20+ deployment scenarios.
- But For most beginners, dev environments means 0 GPUs, and that’s fine.
- You can now easily start with a minimal, CPU-only vLLM stack right on your laptop's k8s using the official pre-built vllm CPU image from [AWS ECR](https://gallery.ecr.aws/q9t5s3a7/vllm-cpu-release-repo).

### 1. Production-stack Deployment Steps
1. Prerequisites Deployment
   ```nginx
   $ Kubectl apply -f deployment_cpu-prereqs.yml
   ```
2. vLLM production stack deployment
   ```nginx
     helm repo add vllm https://vllm-project.github.io/production-stack
     helm repo update
     helm install vllm-cpu vllm/vllm-stack -f cpu-tinyllama-values.yaml
   ```
### 2. Vanilla vLLM deployment
1. Prerequisites Deployment (vpc/secrets/ingress)
   ```nginx
   ```
3. vLLM engine Depoyment
   ```nginx
  
   ```
## 🛠️ Troubleshooting
### 1. Resource starvation
If you have errors such as:
```
pod default/vllm-cpu-deployment-router-f6d6bc958-hszr2
│ Events:
││ Type    Reason           Age  From                                     Message                                  ││
   ----    ---------------- ---- ----------------- ------------------------------------------------------------------
││ Warning FailedScheduling 39m  default-scheduler 0/2 nodes are available: 1 Insufficient cpu, 2 Insufficient memory.
││                               preemption: 0/2 nodes are available: 2 No preemption victims found for incoming pod.
```
**Solution**
- Use lightweight prod-stack configuration [cpu-tinyllama-values.yaml](./cpu-tinyllama-values.yaml) ➡️`tested on a 4 CPU 7.4GB RAM node`
### 2. AMD minimum requirement
>[!warning]
> 3rd Generation AMD EPYC processors (Milan) do not support AVX-512 instructions.

 You need at least 4th gen processors (Zen 4) or higher to support full AVX512 insutruction set to run vLLM inference.
 otherwise you wil receive the below exit 132. 
 ```
 State:       Waiting
 Reason:      CrashLoopBackOff
 Exit Code:   132
❌ Illegal instruction (e.g., AVX512 or BF16 ops on older CPUs).
 ```
**Root Cause:**

✅ Supports: AVX2, FMA, SSE
❌ Does NOT support: AVX-512, BF16 (bfloat16), AMX / VNNI

**Solution**
- Choose a newer generation
- Of use `--dtype=float32` in your vLLM deployment
