# vLLM Lab 🚀

## Overview 📌

This repository contains Terraform configurations for deploying [vLLM](https://github.com/vllm-project/vllm) on Kubernetes clusters across multiple cloud providers, including Civo, Oracle Cloud (OCI), AWS, GCP, and Azure. This setup is based on the [llmcache vllm production-stack](https://github.com/llmcache/vllm-production-stack) project.

> [!TIP]
> For non Kubernetes deployments including CPU builds please check my [Installation.tutorial](./docs/Installation.md)

## Supported Platforms 🌎

- **Civo Kubernetes** ☁️
- **Oracle Cloud (OCI) OKE** 🏛️
- **Amazon Web Services (AWS) EKS** 🟠
- **Google Cloud Platform (GCP) GKE** 🔵
- **Microsoft Azure AKS** 🔷

## VLLM Features ✨
- **PagedAttention 🚀**: Enables efficient memory management to handle large context sizes, reducing redundant computation and maximizing GPU utilization.
- **Continuous Batching 📦**: Dynamically schedules incoming requests for maximum throughput.
- **Multi-GPU and Distributed Support**: Seamless scaling across multiple GPUs and nodes.
- **Fast Token Generation ⚡**: Optimized kernel implementation speeds up inference performance.
- **Flexible Deployment**: Works with Kubernetes, Docker, and cloud-based orchestration tools.
- **Multi-Backend Support 🔗**: Works across different cloud providers and Kubernetes environments.

# Production stack features
- **Interface Design:** Production Stack and LMCache is built as an open, extensible framework, intentionally leaving room for community contributions and innovations. Keeping the interface flexible to support more storage and compute devices in the future.
- **vLLM Support:** LMCache supports the latest vLLM versions through the KV connector interface ([PR](https://github.com/vllm-project/vllm/pull/12953)) and will continue to contribute and support the latest vLLM by leveraging an vLLM upstream connector.
- **KV Cache Performance:** LMCache has advanced KV cache optimizations—efficient **KV transfer and blending**, particularly useful for long-context inference.
- **Developer Friendliness:** In Production Stack and LMCache, operators can directly program LLM serving logics in Python, allowing more optimizations in the long run. Production stack is also easy to setup in 5 minutes [here ](https://github.com/vllm-project/production-stack/tree/main/tutorials).
## Deployment Guide 🛠️

### Prerequisites ✅

Ensure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/downloads) 🌍
- [kubectl](https://kubernetes.io/docs/tasks/tools/) ⛵
- Cloud CLI tools:
  - [Civo CLI](https://www.civo.com/docs) ⚡
  - [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cli.htm) ☁️
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) 🟠
  - [gcloud CLI](https://cloud.google.com/sdk/docs/install) 🔵
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) 🔷

### Setup Instructions 📖

Each cloud provider has its own Terraform configuration. Follow these steps:

#### 1. Clone the Repository 🏗️

```bash
git clone https://github.com/brokedba/vllm_lab.git
cd vllm_lab
```

#### 2. Initialize Terraform ⚙️

Navigate to the specific cloud provider directory and initialize Terraform:

```bash
cd terraform/<provider>
terraform init
```

#### 3. Customize Variables ✏️

Update the `terraform.tfvars` file with your credentials and configuration options.

#### 4. Deploy the Cluster 🚀

```bash
terraform apply -auto-approve
```

#### 5. Deploy vLLM 🧠

Once the Kubernetes cluster is up, deploy `vLLM` using Helm:

```bash
helm repo add vllm https://vllm-project.github.io/helm-charts/
helm install vllm vllm/vllm --namespace vllm --create-namespace
```

## Structure 📂

```
vllm-lab/
├── terraform/
│   ├── civo/
│   ├── oci/
│   ├── aws/
│   ├── gcp/
│   ├── azure/
├── helm/
│   ├── values.yaml
│   ├── templates/
└── README.md
```

## Next Steps ⏭️

- Implement monitoring with Prometheus/Grafana 📊
- Add autoscaling configurations for vLLM 📈
- Improve security configurations 🔒

## Contributions 🤝

PRs and issues are welcome! 🚀

