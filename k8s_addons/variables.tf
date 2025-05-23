variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = ""
}

variable "external_secrets_irsa_role_arn" {
  description = "external_secrets_irsa_role_arn"
  type        = string
  default     = ""
}

variable "argocd_hostname" {
  description = "Hostname for ArgoCD UI ingress"
  type        = string
  default     = ""
}

variable "argocd_ssl_cert_arn" {
  description = "ARN of the SSL certificate for ArgoCD UI"
  type        = string
  default     = ""
}

variable "sonarqube_hostname" {
  description = "Hostname for ArgoCD UI"
  type        = string
  default     = ""
}

variable "sonarqube_ssl_cert_arn" {
  description = "ARN of the SSL certificate for ArgoCD UI"
  type        = string
  default     = ""
}

variable "grafana_hostname" {
  description = "Hostname for Grafana UI"
  type        = string
  default     = ""
}

variable "grafana_ssl_cert_arn" {
  description = "ARN of the SSL certificate for Grafana UI"
  type        = string
  default     = ""
}

variable "greencity_helm_repo_url" {
  description = "URL of the GitHub repository with GreenCity Helm charts"
  type        = string
  default     = ""
}

variable "greencity_backcore_chart_name" {
  description = "URL of the GitHub repository with GreenCity Helm charts"
  type        = string
  default     = "greencity-backcore"
}

variable "greencity_backuser_chart_name" {
  description = "URL of the GitHub repository with GreenCity Helm charts"
  type        = string
  default     = "greencity-backuser"
}

variable "greencity_frontend_chart_name" {
  description = "URL of the GitHub repository with GreenCity Helm charts"
  type        = string
  default     = "greencity-frontend"
}

variable "artifactory_database_password" {
  description = "Artifactory database password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "artifactory_ui_ip" {
  description = "Artifactory ip address to access UI"
  type        = string
  default     = ""
  sensitive   = true
}

variable "artifactory_ui_username" {
  description = "Artifactory UI username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "artifactory_ui_password" {
  description = "Artifactory UI password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "artifactory_domain_name" {
  description = "Nexus domain name"
  type        = string
  default     = ""
}

variable "artifactory_ssl_certificate_arn" {
  description = "nexus SSL Certificate ARN"
  type        = string
  default     = ""
}