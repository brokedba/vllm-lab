## Intro
- Production-stack tutorials folder contains 20+ deployment scenarios.
- But For most beginners, dev environments means 0 GPUs, and that’s fine.
- You can now easily start with a minimal, CPU-only vLLM stack right on your laptop's k8s using the official pre-built vllm CPU image from [AWS ECR](https://gallery.ecr.aws/q9t5s3a7/vllm-cpu-release-repo).

### 1. Production-stack Deployment Steps
- Prerequisite:
A. Install Helm:
   ```nginx
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    sudo ./get_helm.sh 
    ls -l /usr/local/bin/helm
    ln -s /usr/local/bin/helm /usr/bin/helm
    which helm
   ```

1. Prerequisites Deployment
   ```nginx
   $ Kubectl apply -f deployment_cpu-prereqs.yml
   ```
   - (OPTIONAL) local-path-provisioner ( if no storage class exists)
   ```nginx
   # 1. Install the local-path-provisioner Helm chart:
    kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.31/deploy/local-path-storage.yaml
   
   # 2. Set local-path as the default StorageClass
   kubectl patch storageclass local-path -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'
   ```
3. vLLM production stack deployment
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
│ Events: pod default/vllm-cpu-deployment-router-f6d6bc958-hszr2
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
Old CPUs (AMD < 3gen, Intel Xeon < Phi x200 , Intel < Skylake-SP / Skylake-X)

✅ Supports: AVX2, FMA, SSE

❌ Does NOT support: AVX-512, BF16 (bfloat16), AMX / VNNI


**Solution**
- Choose a newer generation 
### 1. CrashLoopBackOff Exit Code 132:

**Root cause:**
```
Describe(default/vllm-cpu-tinyllama-cpu-deployment-vllm-6f5f7776f9-lzbhh) 
   State:          Waiting                                                                                                              ││       Reason:       CrashLoopBackOff                                                                                                ││     Last State:     Terminated                                                                                                      ││       Reason:       Error                                                                                                            ││       Exit Code:    132      
Startup probe failed: ... connection refused
log of the container :
 INFO 06-24 23:08:54 [__init__.py:239] Automatically detected platform cpu.                                                              ││ Stream closed EOF for default/vllm-cpu-tinyllama-cpu-deployment-vllm-6f5f7776f9-lzbhh (vllm) 
```
 This points to a classic Illegal Instruction (SIGILL) error, which is often related to CPU instruction set compatibility.

 1. **Debugging**
 ```nginx
kubectl debug -it node/localhost.localdomain --image=public.ecr.aws/q9t5s3a7/vllm-cpu-release-repo:v0.8.5.post1 -- bash
# Once inside
python -c "import torch, platform, subprocess, os; print(platform.processor());"
x86_64
```
-  If it runs successfully and prints processor info: This means the base image and PyTorch can run without SIGILL. The issue might then be specific to vLLM's initialization, or related to the environment where the main vLLM process runs (e.g., startup scripts, arguments).   
