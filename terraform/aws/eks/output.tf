output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnets" {
  value = module.vpc.private_subnets
}
output "public_subnets" {
  value = module.vpc.public_subnets
}


output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged in with the correct AWS profile and run the following command to update your kubeconfig"
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${module.eks.cluster_name}"
  sensitive   = true
}

# output "kubeconfig_path" {
#   description = "Local path to the generated kubeconfig"
#   value       = local_file.kubeconfig.filename
#   sensitive   = true
# }

##### Network outputs #####
output "vpc_cidr" {
  value = data.aws_vpc.selected.cidr_block
}

# Output for cluster subnets  
output "cluster_subnets_info" {
  description = "Information about private subnets used by the EKS cluster"
  value = {
    for s in data.aws_subnet.cluster_subnets :
    s.id => {
      id               = s.id
      cidr             = s.cidr_block
      tags             = s.tags
      name             = lookup(s.tags, "Name", "")
      availability_zone = s.availability_zone
    }
  }
}

output "cluster_public_subnets_info" {
  description = "Information about public subnets used by the EKS cluster"
  value = {
    for s in data.aws_subnet.cluster_public_subnets :
    s.id => {
      id               = s.id
      cidr             = s.cidr_block
      tags             = s.tags
      name             = lookup(s.tags, "Name", "")
      availability_zone = s.availability_zone
    }
  }
}

output "grafana_forward_cmd" {
  description = "Command to forward Grafana port"
  value       = "kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n kube-prometheus-stack"
}

# Output that defaults to null when no ingress exists  
output "vllm_ingress_hostname" {  
  description = "The hostname of the vLLM ingress load balancer (null if no ingress configured)"  
  value = var.enable_vllm ? try(  
    data.kubernetes_ingress_v1.vllm_ingress[0].status[0].load_balancer[0].ingress[0].hostname,  
    null  # Explicitly return null if ingress doesn't exist or has no hostname  
  ) : null  
  depends_on = [helm_release.vllm_stack]  
}  
  
# Data source that only tries to read ingress if vLLM is enabled  
data "kubernetes_ingress_v1" "vllm_ingress" {  
  count = var.enable_vllm ? 1 : 0  
    
  metadata {  
    name      = "vllm-gpu-ingress-router"  # Adjust to match your actual ingress name  
    namespace = kubernetes_namespace.vllm["vllm"].metadata[0].name  
  }  
    
  depends_on = [helm_release.vllm_stack]  
}