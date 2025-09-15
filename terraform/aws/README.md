# 🧑🏼‍🚀 vLLM Production Stack on Amazon EKS with terraform 
✍🏼 This terraform stack delivers a **production-ready vLLM serving environment** On Amazon EKS supporting both CPU/GPU inference with operational best practices embeded in [AWS Integration and Automation](https://github.com/aws-ia) (security, scalability, observability).

|Project Item |Description|
|---|---|
| **Author** | [@cloudthrill](https://cloudthrill.ca) |
| **Stack**  | Terraform ◦ AWS ◦ EKS ◦ Calico ◦ Helm ◦ vLLM |
| **Module** | Highly customizable, lightweight EKS blueprint for deploying vLLM on enterprise-grade clusters 
| **CNI**    | AWS VPC with full-overlay **Calico** network
| **Inference hardware** | Either CPU or GPU through a switch flag
 
## 📋 Table of Contents

1. [Project structure](#project-structure)  
2. [Prerequisites](#prerequisites)  
3. [Quick start](#quick-start)  
4. [Configuration knobs](#configuration-knobs)  
5. [Verify the deployment](#verify-the-deployment)  
6. [Troubleshooting](#troubleshooting)  
7. [Destroy](#destroy)
---
## 📂 Project Structure
```nginx
./
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
├── env-vars.template
├── terraform.tfvars.template
├── modules/
│   ├── aws-networking/
│   │   └── aws-vpc/
│   ├── aws-eks/
│   ├── eks-blueprints-addons/
|   ├── eks-data-addons/
│   └── llm-stack
|       ├── helm/
|           ├── cpu/
|           └── gpu/  
├── config/
│   ├── calico-values.tpl
│   └── kubeconfig.tpl
└── README.md                          # ← you are here                  

```
---
## ✅ Prerequisites

| Tool | Version tested | Notes |
|------|---------------|-------|
| **Terraform** | ≥ 1.5.7 | tested on 1.5.7 |
| **AWS CLI v2** | ≥ 2.16 | profile / SSO auth |
| **kubectl** | ≥ 1.30 | ±1 of control-plane |
| **helm** | ≥ 3.14 | used by `helm_release` |
| **jq** | optional | JSON helper |
| **openssl / base64** | optional | secret helpers |

<details> 
 <summary><b>Install tools (Ubuntu/Debian)</b></summary>

 ```bash
# Install tools
sudo apt update && sudo apt install -y jq curl unzip gpg
wget -qO- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip -q awscliv2.zip && sudo ./aws/install && rm -rf aws awscliv2.zip
curl -sLO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && sudo install kubectl /usr/local/bin/ && rm kubectl
curl -s https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null && echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm.list && sudo apt update && sudo apt install -y helm
```
</details>

**Configure AWS**
```nginx
aws configure --profile myprofile
export AWS_PROFILE=myprofile        # ← If null Terraform exec auth will use the default profile
```
---

## 🏗️ What Terraform Deploys
<div align="center">
 
| Layer | Component | CPU Mode | GPU Mode |
|------|-----------|----------|----------|
| **Infrastructure** | VPC + EKS + Calico CNI | ✅ Always deployed | ✅ Always deployed |
| **Add-ons** | EBS, ALB, Prometheus stack | ✅ Always deployed | ✅ Always deployed |
| **vLLM Stack** | Secrets + Helm chart | ✅ Deploy on CPU nodes | ✅ + GPU nodes + NVIDIA operator |
| **Networking** | Load balancer + Ingress | ✅ ALB configuration | ✅ ALB configuration |
</div>
<div align="center">
<img width="266" height="496" alt="image" src="https://github.com/user-attachments/assets/47123e7d-5d30-448d-9266-ba7082403d3b" />
<p><em>Figure-1 dependency chain of the eks addon layer with vllm on cpu</em></p>
</div>  
 
### 1.📶 Networking 
* Custom `/16` VPC with 3 public + 3 private subnets
* Single NAT GW (cost-optimized)
* **Calico overlay CNI** with VXLAN encapsulation (110+ pods/node vs 17 with VPC CNI)
* AWS Load Balancer Controller for ingress exposure 
* Kubernetes-friendly subnet tagging and IAM roles
### 2. ☸️ EKS Cluster 
*  Control plane v1.30 with two managed node-group Types

| Pool | Instance | Purpose |
|------|----------|---------|
| `cpu_pool` (default) | **t3a.large** (2 vCPU / 8 GiB) | control & CPU inference |
| `gpu_pool` *(optional)* | **g5.xlarge** (1 × A10 GPU) | heavy inference or training |

### 3. 📦 Add-ons (“Blueprints”)
Core EKS add-ons via [terraform-aws-eks-**blueprints-addons**](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons) along with gpu operator via [terraform-aws-eks-data-addons](https://github.com/aws-ia/terraform-aws-eks-data-addons).

| Category      | Add-on |
|---------------|--------|
| **CNI**       | **Calico overlay** (primary) (VPC-CNI removed) |
| **Storage**   | **EBS CSI** (block)<br/>**EFS CSI** (shared) |
| **Ingress/LB**| **AWS Load Balancer Controller** (ALB/NLB) |
| **EKS add-ons**      | CoreDNS, kube-proxy, Metrics Server |
| **Observability** | kube-prometheus-stack, CloudWatch metrics |
| **Security**  | cert-manager, External-DNS / External-Secrets |
| **Optional**  | NVIDIA Optional GPU operator toggle |
 
### 4. 🧠 vLLM Production Stack (CPU/GPU)
- **Model serving**: (Default) Single TinyLlama-1.1B model replica 
- **Load balancing**: Round-robin router service
- **Hugging Face token**: stored as Kubernetes Secret
- **LLM Storage**: Init container Persistent model caching under `/data/models/`
- **Default Helm charts**: [cpu-tinyllama-light-ingress](./modules/llm-stack/helm/cpu/cpu-tinyllama-light-ingress-tpl) | [gpu-tinyllama-light-ingress](./modules/llm-stack/helm/gpu/gpu-tinyllama-light-ingress-tpl)


---

## 💡 Hardware Options
You can choose to deploy VLLM production stack on either CPU or GPU using the `inference_hardware` parameter
<div align="center">
<img width="703" height="676"  alt="image" src="https://github.com/user-attachments/assets/20a719c9-7a7e-4689-8b15-acfd84448f21" />
<p><em>Figure-2 dependency chain of vllm stack cpu resource</em></p>
</div>

<div align="center">
 
| Mode | Setting | Resources |
|------|---------|-----------|
| **CPU** | `inference_hardware = "cpu"` | Uses existing CPU nodes (t3a.large) |
| **GPU** | `inference_hardware = "gpu"` | Provisions GPU nodes (g5.xlarge + NVIDIA operator) |
</div>

 # 🖥️ AWS GPU Instance Types Available
(T4 · L4 · V100 · A10G · A100) . Read the full list of AWS GPU instance offering [here](https://instances.vantage.sh/?id=f7932a1aadf6b5f3810c902c0e155052f5095bbb).
<details><summary><b> Available GPU instances</b></summary>
<br>
 
| AWS EC2 Instance | vCPUs | Memory (GiB) | GPUs | GPU Memory (GiB) | Best For |
|---|---|---|---|---|---|
| **NVIDIA Tesla T4** |
| `g4dn.xlarge`   | 4  | 16  | 1 | 16 | Small inference |
| `g4dn.2xlarge`  | 8  | 32  | 1 | 16 | Medium inference |
| `g4dn.4xlarge`  | 16 | 64  | 1 | 16 | Large inference |
| `g4dn.12xlarge` | 48 | 192 | 4 | 64 | Multi-GPU inference |
| **NVIDIA L4** |
| `g6.xlarge`   | 4  | 16  | 1 | 24 | Cost-effective inference |
| `g6.2xlarge`  | 8  | 32  | 1 | 24 | Balanced inference workloads |
| `g6.4xlarge`  | 16 | 64  | 1 | 24 | Large-scale inference |
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
</details>

### GPU Specifications  
| GPU Type           |  Best For                         | Relative Cost |
|--------------------|----------------------------------|---------------|
| NVIDIA Tesla T4    | ML inference, small-scale training | $             |
| NVIDIA L4          | Cost-effective inference, edge AI | $             |
| NVIDIA A10G        | Balanced GPU workloads           | $$            |
| NVIDIA Tesla V100  | Large-scale ML training & inference | $$$           |
| NVIDIA A100        | Cutting-edge AI workloads        | $$$$          |

# 🛠️Configuration knobs 
This stack provides extensive customization options to tailor your deployment:
| Variable               | Default        | Description                 |
|------------------------|----------------|-----------------------------|
| `region`               | `us-east-2`    | AWS Region                 |
| `pod_cidr`             | `192.168.0.0/16` | Calico Pod overlay network        |
| `inference_hardware`   | `cpu \| gpu`   | Select node pools           |
| `enable_efs_csi_driver`| `true`         | Shared storage              |
| `enable_vllm`          | `true`         | Deploy stack                |
| `hf_token`             | **«secret»**   | HF model download token     |
| `enable_prometheus`    |  true          |	prometheus-grafana stack    |
| `cluster_version` | `1.30` | Kubernetes version |
| `nvidia_setup` | `plugin` | GPU setup mode (plugin/operator) |

### 📋 Complete Configuration Options

**This is just a subset of available variables.** For the full list of 20+ configurable options including:
- **Node group** sizing (CPU/GPU pools)
- **Storage drivers** (EBS/EFS) 
- **Observability stack** (Prometheus/Grafana)
- **Security settings** (cert-manager, external-secrets)
- **Network configuration** (VPC CIDR, subnets)

**📓** See the complete configuration template:
- **Environment variables**: [`env-vars.template`](./env-vars.template)
- **Terraform variables**: [`terraform.tfvars.example`](./terraform.tfvars.example)
---
## 🚀 Quick start
### ⚙️ Provisioning logic
The deployment automatically provisions only the required infrastructure based on your hardware selection.

| Phase | Component | Action | Condition |
|-------|-----------|--------|-----------|
| **1. Infrastructure** | VPC | Provision VPC with 3 public + 3 private subnets | Always |
| | EKS | Deploy v1.30 cluster + CPU node group (t3a.large) | Always |
| | CNI | Remove aws-node, install Calico overlay (VXLAN) | Always |
| | Add-ons | Deploy EBS CSI, ALB controller, kube-prometheus | Always |
| **2. vLLM Stack** | | | `enable_vllm = true` |
| | HF secret| Deploy Create `hf-token-secret` for Hugging Face | `enable_vllm = true` |
| | CPU Deployment | Deploy vLLM on existing CPU nodes | `inference_hardware = "cpu"` |
| | GPU Infrastructure | Provision GPU node group (g5.xlarge) | `inference_hardware = "gpu"` |
| | GPU Operator | Deploy NVIDIA operator/plugin | `inference_hardware = "gpu"` |
| | GPU Deployment | Deploy vLLM on GPU nodes with scheduling | `inference_hardware = "gpu"` |
| | Application | Deploy TinyLlama-1.1B Helm chart to `vllm` namespace | `enable_vllm = true` |
| **3. Networking** | Load Balancer | Configure ALB and ingress for external access | `enable_vllm = true` |
| **4. model storage** | loaded locally | Using init container | -> `/data/models` |
 
---
## 🔵 Deployment Steps

### 1. Clone the repository
```nginx
git clone https://github.com/vllm-project/production-stack
cd production-stack/tutorials/terraform/eks/
```
### 2. Configure the Environment
```nginx
cp env-vars.template env-vars
vim env-vars  # Set HF token and customize deployment options
source env-vars
```
**Usage examples**

- **Option 1: Throug Environment Variables**
  
  ```nginx
  # Copy and customize
  $ cp env-vars.template env-vars
  $ vi env-vars
  ################################################################################
  # EKS Cluster Configuration
  ################################################################################
  # ☸️ EKS cluster basics
  export TF_VAR_cluster_name="vllm-eks-prod" # default: "vllm-eks-prod"
  export TF_VAR_cluster_version="1.30"       # default: "1.30" - Kubernetes cluster version
   ################################################################################
   # 🤖 NVIDIA setup selector
   #   • plugin           -> device-plugin only
   #   • operator_no_driver -> GPU Operator (driver disabled)
   #   • operator_custom  -> GPU Operator with your YAML
   ################################################################################
   export TF_VAR_nvidia_setup="plugin" # default: "plugin" 
   ################################################################################
   # 🧠 LLM Inference Configuration
   ################################################################################
   export TF_VAR_enable_vllm="true"         # default: "false" - Set to "true" to deploy vLLM
   export TF_VAR_hf_token=""                # default: "" - Hugging Face token for model download (if needed)
   export TF_VAR_inference_hardware="gpu"   # default: "cpu" - "cpu" or "gpu"
   ################################################################################
   export TF_VAR_enable_vllm=true # default: false
   export TF_VAR_hf_token= # default: ""
   export TF_VAR_inference_hardware="gpu" # default: "cpu"
   export TF_VAR_nvidia_setup="plugin" # default: "" 
   # Paths to Helm chart values templates for vLLM.
   # These paths are relative to the root of your Terraform project.
   export TF_VAR_gpu_vllm_helm_config="./modules/llm-stack/helm/gpu/gpu-tinyllama-light-ingress.tpl" # default: ""
   export TF_VAR_cpu_vllm_helm_config="./modules/llm-stack/helm/cpu/cpu-tinyllama-light-ingress.tpl" # default: ""
   ################################################################################
   # ⚙️ Node-group sizing
   ################################################################################
   # CPU pool (always present)
   export TF_VAR_cpu_node_min_size="1"     # default: 1
   export TF_VAR_cpu_node_max_size="3"     # default: 3
   export TF_VAR_cpu_node_desired_size="2" # default: 2
   # GPU pool (ignored unless inference_hardware = "gpu")
   export TF_VAR_gpu_node_min_size="1"     # default: 1
   export TF_VAR_gpu_node_max_size="1"     # default: 1
   export TF_VAR_gpu_node_desired_size="1" # default: 1
   ...snip
   $ source env-vars
   ```
- **Option 2: Through Terraform Variables**
  ```bash
   # Copy and customize  
   $ cp terraform.tfvars.example terraform.tfvars
   $ vim terraform.tfvars
  ```

### 3. Deploy Infrastructure
```nginx
terraform init
terraform plan
terraform apply
```
---



## 🧪 Quick Test

**1. Extracting the Router URL via AWS ALB Ingress**

- You can find the ALB-based router endpoint using the `vllm_ingress_hostname` Terraform output, or by running the following command:

```nginx
$ k get ingress -n vllm -o json| jq -r .items[0].status.loadBalancer.ingress[].hostname
k8s-vllm-vllmingr-983dc8fd68-161738753.us-east-2.elb.amazonaws.com
export vllm_api_url="https://k8s-vllm-vllmingr-983dc8fd68-161738753.us-east-2.elb.amazonaws.com/v1"
```
**2. List models**
```bash
curl -s ${vllm_api_url}/models | jq .
```
**3. Completion**
```nginx
curl ${vllm_api_url}/completions     -H "Content-Type: application/json"     -d '{
        "model": "/data/models/tinyllama",
        "prompt": "Who won the World Cup 2022",
        "max_tokens": 10,
        "temperature": 0
    }'| jq .choices[].text
```

**5. vLLM model service**
```
kubectl -n vllm get svc
```
## 🔬 Observability
 Grafana (if enabled) you can use the AWS LoadBalancer URL → https://"<alb-dns>"/grafana
- Login: admin
- Run the below command to fetch the password
```console
kubectl get secret -n kube-prometheus-stack kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode
```
>[!note]
> In this stack, the vLLM dashboard and service monitoring are automatically configured in Grafana. No manual setup needed. 
><img width="3813" height="1643" alt="image" src="https://github.com/user-attachments/assets/2df312b6-3465-4049-90c8-c33540f5b6d3" />

---
 
# 🎯 Troubleshooting

**1. [Ordering issue with AWS Load Balancer Controller](https://github.com/aws-ia/terraform-aws-eks-blueprints-addons/issues/233)**

With LBC ≥ 2.5.1 the chart enables a MutatingWebhook that intercepts every Service of type LoadBalancer: 
<img width="2162" height="433" alt="image" src="https://github.com/user-attachments/assets/10e00422-436b-4003-a6de-e1edee912da7" />

As a result addons services (i.e cert manager) will timeout waiting for the webhook to be available.
```bash
no endpoints available for service "aws-load-balancer-webhook-service"
```
> **Fix Applied**
>
> We turned off the webhook as we don't use `serviceType: LoadBalancer`here.
> ```nginx
> # in your blueprints-addons block
> aws_load_balancer_controller = {
>  enable_service_mutator_webhook = false   # turns off the webhook
>}
>```
>  **Note:** If you plan to use `serviceType: LoadBalancer`, deploy the LBC add-on first, then apply the rest of the stack.


**2. Calico discovery commands**
```bash
# Calico pods (overlay CNI)
kubectl -n tigera-operator get pods
# 1. kubectl get all -n tigera-operator
# 2. kubectl get installation -o yaml | yq '.items[].spec.cni.type'
# 3. kubectl get ds -n calico-system -w
# 4. kubectl get tigerastatus
```

## 🔧 Cleanup Notes
### Optional Manual Cleanup

In rare cases, you may need to manually clean up some AWS resources while running terraform destroy. Here are the most common scenarios:

**1. load balancer blocking public subnets/igw deletion** 

If using ingress and encountering VPC deletion issues due to an LB creation outside terraform, run the below cleanup commands:
```bash
export PROFILE=profile_name  (ex: default)
export region =<region>       (ex: "us-east-2")
 # 1. Clean up load balancer
 alb_arn=$(aws elbv2 describe-load-balancers \
   --names <Balancer-name> \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text --region $region --profile $PROFILE)
# delete :
aws elbv2 delete-load-balancer --load-balancer-arn "$alb_arn" --region $region --profile $PROFILE 
```
- Clean up associated security groups
list and delete orphan SGs (non-default)
```bash
VPC_ID=$(aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name` && Value==`vllm-vpc`]].VpcId' --output text --profile $PROFILE)
# Deletion
aws ec2 describe-security-groups --filters Name=vpc-id,Values=${VPC_ID} --query "SecurityGroups[?starts_with(GroupName, 'k8s-') || contains(GroupName, 'vllm')].GroupId"    --output text    --profile ${PROFILE} |  tr -s '[:space:]' '\n' |  xargs -r -I{} aws ec2 delete-security-group --group-id {} --profile ${PROFILE}
```

**2. vllm namespace**

If the vLLM namespace gets stuck in "Terminating" state, you might need to patch some finalizers  
```bash
# Remove finalizers from AWS resources
RESOURCE_NAME=$(kubectl get targetgroupbinding.elbv2.k8s.aws -n vllm -o jsonpath='{.items[0].metadata.name}')
kubectl patch targetgroupbinding.elbv2.k8s.aws $RESOURCE_NAME -n vllm --type=merge -p '{"metadata":{"finalizers":[]}}'
kubectl delete targetgroupbinding.elbv2.k8s.aws $RESOURCE_NAME -n vllm --ignore-not-found=true
INGRESS_NAME=$(kubectl get ingress -n vllm -o jsonpath='{.items[0].metadata.name}')
kubectl patch ingress $INGRESS_NAME -n vllm --type=merge -p '{"metadata":{"finalizers":[]}}'
```
**3. Calico Cleanup Jobs**

If encountering job conflicts during Calico removal (i.e: * jobs.batch "tigera-operator-uninstall" already exists) run the below commands
```bash
# use the following commands to delete the jobs manually first:
kubectl -n tigera-operator delete job tigera-operator-uninstall --ignore-not-found=true
kubectl -n tigera-operator delete job tigera-operator-delete-crds --ignore-not-found=true
kubectl delete ns tigera-operator --ignore-not-found=true
```
**Note:** These manual steps are only needed if terraform destroy encounters specific dependency issues. 
## 📚 Additional Resources
- [vLLM Documentation](https://docs.vllm.ai/)
- [terraform-aws-eks](https://github.com/terraform-aws-modules/terraform-aws-eks)
- [EKS Blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [Calico Documentation](https://docs.projectcalico.org/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
