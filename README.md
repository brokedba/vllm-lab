# vLLM Lab

## Overview

This repository contains Terraform configurations for deploying [vLLM](https://github.com/vllm-project/vllm) on Kubernetes clusters across multiple cloud providers, including Civo, Oracle Cloud (OCI), AWS, GCP, and Azure. This setup is based on the [llmcache vllm production-stack](https://github.com/llmcache/vllm-production-stack) project.

## Supported Platforms

- **Civo Kubernetes**
- **Oracle Cloud (OCI) OKE**
- **Amazon Web Services (AWS) EKS**
- **Google Cloud Platform (GCP) GKE**
- **Microsoft Azure AKS**

## Deployment Guide

### Prerequisites

Ensure you have the following installed:

- [Terraform](https://developer.hashicorp.com/terraform/downloads)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- Cloud CLI tools:
  - [Civo CLI](https://www.civo.com/docs)
  - [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cli.htm)
  - [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
  - [gcloud CLI](https://cloud.google.com/sdk/docs/install)
  - [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Setup Instructions

Each cloud provider has its own Terraform configuration. Follow these steps:

#### 1. Clone the Repository

```bash
git clone https://github.com/brokedba/vllm_lab.git
cd vllm_lab
```

#### 2. Initialize Terraform

Navigate to the specific cloud provider directory and initialize Terraform:

```bash
cd terraform/<provider>
terraform init
```

#### 3. Customize Variables

Update the `terraform.tfvars` file with your credentials and configuration options.

#### 4. Deploy the Cluster

```bash
terraform apply -auto-approve
```

#### 5. Deploy vLLM

Once the Kubernetes cluster is up, deploy `vLLM` using Helm:

```bash
helm repo add vllm https://vllm-project.github.io/helm-charts/
helm install vllm vllm/vllm --namespace vllm --create-namespace
```

## Structure

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

## Next Steps

- Implement monitoring with Prometheus/Grafana.
- Add autoscaling configurations for vLLM.
- Improve security configurations.

## Contributions

PRs and issues are welcome! 🚀

