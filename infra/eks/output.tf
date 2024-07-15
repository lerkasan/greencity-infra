output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster endpoint"
}

output "certificate_authority_data" {
  value       = module.eks.cluster_certificate_authority_data
  description = "EKS cluster name"
}

output "oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN"
}

output "eks_worker_nodes_security_group_id" {
  value       = aws_security_group.eks_worker_nodes.id
  description = "EKS worker nodes security group id"
}

