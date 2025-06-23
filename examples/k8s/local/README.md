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

