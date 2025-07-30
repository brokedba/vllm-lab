# vLLM Production Stack on Amazon EKS with terraform
| | |
|---|---|
| **Author** | [@cloudthrill](https://cloudthrill.ca) |
| **Stack**  | Terraform ◦ AWS ◦ EKS ◦ Calico ◦ Helm ◦ vLLM |

This tutorial shows how to stand up a **production-grade vLLM serving
environment** on Amazon EKS with Terraform.
>  Ultra-light blueprint to spin up an **EKS 1.30** cluster, swap the default
> AWS VPC CNI for a full-overlay **Calico** network, and deploy a CPU-GPU
> **vLLM** serving engine (TinyLlama) – all from Terraform.

## 📋 Table of Contents

1. [Prerequisites](#prerequisites)  
2. [Repo layout](#repo-layout)  
3. [Quick start](#quick-start)  
4. [Configuration knobs](#configuration-knobs)  
5. [Verify the deployment](#verify-the-deployment)  
6. [Troubleshooting](#troubleshooting)  
7. [Destroy](#destroy)
---
## ✅ Prerequisites

| Tool | Version tested | Notes |
|------|---------------|-------|
| Terraform | ≥ 1.5.7 | tested on 1.5.7 |
| **AWS CLI v2** | ≥ 2.16 | profile / SSO auth |
| **kubectl** | ≥ 1.30 | ±1 of control-plane |
| **helm** | ≥ 3.14 | used by `helm_release` |
| **jq** | optional | JSON helper |
| **openssl / base64** | optional | secret helpers |
```bash
brew install terraform awscli kubectl helm jq
aws configure --profile myprofile
export AWS_PROFILE=myprofile         # ← Terraform exec auth uses this
```
---

## 🏗️ What Terraform ships
<div align="center">
<img width="266" height="496" alt="image" src="https://github.com/user-attachments/assets/47123e7d-5d30-448d-9266-ba7082403d3b" />
<p><em>Figure-1 dependency chain of the eks addon layer </em></p>
</div>  

* IaC only (no imperative kubectl except for troubleshooting)
### 1. Networking
*  (public + private subnets, NAT, IAM roles, etc.)
* Custom /16 VPC with three public & three private subnets
* 1 NAT GW (single-AZ to save cost)
* Kubernetes-friendly subnet tags
* **Calico overlay CNI** as primary (VXLAN encapsulation) replaces the default AWS VPC CNI (⇒ 110 pods / node)  
### 2. EKS Cluster
*  Control plane v1.30
*  Two managed node-groups & Instance Types

| Pool | Instance | Purpose |
|------|----------|---------|
| `cpu_pool` (default) | **t3a.large** (2 vCPU / 8 GiB) | control & CPU inference |
| `gpu_pool` *(optional)* | **g5.xlarge** (1 × A10 GPU) | heavy inference or training |

### 3. Add-ons (“Blueprints”)
via terraform-aws-eks-**blueprints-addons**

| Category      | Add-on |
|---------------|--------|
| **CNI**       | **Calico overlay** (primary)<br/><sub><sup>*AWS VPC-CNI removed*</sup></sub> |
| **Storage**   | **EBS CSI** (block)<br/>**EFS CSI** (shared) |
| **Ingress/LB**| **AWS Load Balancer Controller** (ALB/NLB) |
| **EKS add-ons**      | CoreDNS, kube-proxy, Metrics Server |
| **Observability** | kube-prometheus-stack, CloudWatch metrics |
| **Security**  | cert-manager, External-DNS / External-Secrets |
| **Optional**  | NVIDIA Optional GPU operator toggle |

* Core EKS add-ons via *terraform-aws-eks-blueprints-addons* (ALB controller, EBS CSI, kube-prom, …)
### 4. vLLM Production Stack (CPU/GPU)
- Single TinyLlama-1.1B model replica
- Round-robin router service
- Hugging Face token stored as Kubernetes Secret

 
> Diagram 👉 `docs/architecture.drawio.png`

---
## Repo layout
```nginx
.
├── main.tf
├── network.tf
├── storage.tf
├── provider.tf
├── variables.tf
├── output.tf
├── cluster-tools.tf
├── datasources.tf
├── iam_role.tf
├── vllm-production-stack.tf
├── modules/
│   ├── aws-networking/
│   │   └── aws-vpc/
│   ├── aws-eks/
│   ├── eks-blueprints-addons/
│   └── eks-data-addons/
├── config/
│   ├── calico-values.tpl
│   └── kubeconfig.tpl
└── README.md                          # ← you are here                  

```
<div align="center">
<img width="703" height="676"  alt="image" src="https://github.com/user-attachments/assets/20a719c9-7a7e-4689-8b15-acfd84448f21" />
<p><em>Figure-1 dependency chain of vllm stack cpu resource</em></p>
</div>

## AWS EC2 GPU-Enabled Instance Types

# AWS EC2 GPU-Enabled Instances  
(T4 · V100 · A100 · A10G)

| AWS EC2 Instance | vCPUs | Memory (GiB) | GPUs | GPU Memory (GiB) | Best For |
|---|---|---|---|---|---|
| **NVIDIA Tesla T4** |
| `g4dn.xlarge`   | 4  | 16  | 1 | 16 | Small inference |
| `g4dn.2xlarge`  | 8  | 32  | 1 | 16 | Medium inference |
| `g4dn.4xlarge`  | 16 | 64  | 1 | 16 | Large inference |
| `g4dn.12xlarge` | 48 | 192 | 4 | 64 | Multi-GPU inference |
| **NVIDIA Tesla V100** |
| `p3.2xlarge`  | 8  | 61  | 1 | 16 | Training & inference |
| `p3.8xlarge`  | 32 | 244 | 4 | 64 | Multi-GPU training |
| `p3.16xlarge` | 64 | 488 | 8 | 128 | Large-scale training |
| **NVIDIA A100** |
| `p4d.24xlarge` | 96 | 1 152 | 8 | 320 | Large-scale AI training |
| **NVIDIA A10G** |
| `g5.xlarge`   | 4  | 16  | 1 | 24 | General GPU workloads |
| `g5.2xlarge`  | 8  | 32  | 1 | 24 | Medium GPU workloads |
| `g5.4xlarge`  | 16 | 64  | 1 | 24 | Large GPU workloads |
| `g5.8xlarge`  | 32 | 128 | 1 | 24 | Large-scale inference |
| `g5.12xlarge` | 48 | 192 | 4 | 96 | Multi-GPU training |
| `g5.24xlarge` | 96 | 384 | 4 | 96 | Ultra-large-scale training |
| `g5.48xlarge` | 192| 768 | 8 | 192| Extreme-scale training |

---

### GPU Specifications  
| GPU Type           |  Best For                         | Relative Cost |
|--------------------|----------------------------------|---------------|
| NVIDIA Tesla T4    | ML inference, small-scale training | $             |
| NVIDIA Tesla V100  | Large-scale ML training & inference | $$$           |
| NVIDIA A100        | Cutting-edge AI workloads        | $$$$          |
| NVIDIA A10G        | Balanced GPU workloads           | $$            |

## Quick start
```bash
# 1. Clone
git clone https://github.com/brokedba/vllm-lab && cd vllm-lab

# 2. Optional – configure remote backend
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvar

# 3. Seed secrets
export TF_VAR_hf_token="hf_XXXXXXXXXXXXXXXXXXXX"   # Hugging-Face PAT

# 4. Plan & apply
terraform init
terraform apply
```
<details> <summary><b>What happens under the hood</b></summary>

1. VPC with three public / private subnets
2. EKS 1.30 cluster + managed node group (t3.medium)
3. Disable aws-node; install Calico overlay VXLAN
4. Provision EBS CSI, ALB controller, kube-prom stack, etc.
5. Create opaque secret hf-token-secret
6. Deploy vLLM Helm chart (tinyllama-cpu) to namespace vllm
</details>

## Configuration knobs
### 🛠️ Configuration Highlights

| Variable               | Default        | Description                 |
|------------------------|----------------|-----------------------------|
| `region`               | `us-east-2`    | AWS Region                 |
| `pod_cidr`             | `192.168.0.0/16` | Pod overlay network        |
| `inference_hardware`   | `cpu \| gpu`   | Select node pools           |
| `enable_efs_csi_driver`| `true`         | Shared storage              |
| `enable_vllm`          | `true`         | Deploy stack                |
| `hf_token`             | **«secret»**   | HF model download token     |

Variable	Default	Description
region	us-east-2	AWS region
inference_hardware	cpu	set gpu to enable GPU node group
pod_cidr	192.168.0.0/16	Calico overlay pool
enable_efs_csi_driver	false	dynamic EFS volumes
enable_prometheus	true	kube-prometheus-stack
enable_vllm	true	install vLLM helm
hf_token	required	Hugging Face PAT

## 🧪 Quick Test
1. Port-forward vLLM router
```bash 
kubectl -n vllm port-forward svc/vllm-router 8080:80 &
```
2. List models
```bash
curl -s http://localhost:8080/v1/models | jq .
```
3. Completion
```bash
curl -s http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"TinyLlama/TinyLlama-1.1B-Chat-v1.0","prompt":"Once upon a time,","max_tokens":10}' | jq 
```
When model loaded locally using init-container:
```
bash
curl -s http://localhost:8080/v1/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"/data/models/tinyllama","prompt":"Once upon a time,","max_tokens":10}' | jq 
```
4. Using ingress
```nginx
$ k get ingress -n vllm -o json| jq -r .items[0].status.loadBalancer.ingress[].hostname
k8s-vllm-vllmingr-983dc8fd68-161738753.us-east-2.elb.amazonaws.com

curl http://k8s-vllm-vllmingr-983dc8fd68-161738753.us-east-2.elb.amazonaws.com/v1/completions     -H "Content-Type: application/json"     -d '{
        "model": "/data/models/tinyllama",
        "prompt": "San Francisco is a",
        "max_tokens": 10,
        "temperature": 0
    }'| jq .choices[].text

```
5. TinyLlama service
```
kubectl -n vllm get svc
```
- Grafana (if enabled) → https://<alb-dns>/grafana
- Login: admin / <terraform output grafana_admin_password>.

## Troubleshooting
Calico
```bash
# Calico pods (overlay CNI)
kubectl -n tigera-operator get pods
```
**[Ordering issue with AWS Load Balancer Controller](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/233)**

🎯 Root cause
With LBC ≥ 2.5.1 the chart enables a MutatingWebhook that intercepts every Service of type LoadBalancer: 
<img width="2162" height="433" alt="image" src="https://github.com/user-attachments/assets/10e00422-436b-4003-a6de-e1edee912da7" />
>[!NOTE]
>As a result addons that have services (i.e cert manager)  may timeout waiting for the webhook to be available.
>```bash
>no endpoints available for service "aws-load-balancer-webhook-service"
>```

**Fix** 

Users can safely turn off the webhook if they are not using the `serviceType: LoadBalancer` in any of their software. If they are using it then they should deploy the LBC add-on first then the rest (**terraform apply twice**).
```nginx
# in your blueprints-addons block
aws_load_balancer_controller = {
  enable_service_mutator_webhook = false   # turns off the webhook
}
```
## Destroy
> If you face terraform destroy VPC  DependencyViolation issues because of a Load Balancer creation outside terraform, 
use the following commands to delete the ALB manually first:
```bash
 # 1. load balancer 
 alb_arn=$(aws elbv2 describe-load-balancers \
   --names <Balancer-name> \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text --region <region> --profile profile_name)
# delete :
aws elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" --region <region> --profile profile_name 

# 2. security groups
# list orphan SGs (non-default)
aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values=$VPC_ID \
  --query "SecurityGroups[?GroupName!='default'].[GroupId,GroupName]" \
  --output table --profile $AWS_PROFILE

# delete
aws ec2 delete-security-group --group-id sg-xxxxxxxx --profile $AWS_PROFILE
```
