variable "domain_name" {
  description   = "Domain name"
  type          = string
  default       = ""
}

variable "cluster_name" {
  description   = "Cluster name"
  type          = string
  default       = ""
}

variable "k8s_namespaces" {
  description   = "k8s namespaces"
  type          = list(string)
  default       = []
}

variable "oidc_provider_arn" {
  description   = "OIDC provider ARN"
  type          = string
  default       = ""
}

variable "parameter_arns" {
  description   = "ARNs of SSM parameters"
  type          = list(string)
  default       = []
}

variable "kms_key_arns" {
  description   = "ARNs of KMS keys to decrypt SSM parameters"
  type          = list(string)
  default       = []
}

variable "datadog_api_key" {
  description   = "Datadog API key"
  type          = string
  sensitive     = true
}

variable "datadog_site" {
  description   = "Datadog site"
  type          = string
  sensitive     = true
}

variable "grafana_admin_user" {
  description   = "Grafana admin user"
  type          = string
  sensitive     = true
}

variable "grafana_admin_password" {
  description   = "Grafana admin password"
  type          = string
  sensitive     = true
}

variable "sonarqube_db_instance_address" {
  description   = "SonarQube DB instance address"
  type          = string
  sensitive     = true
}

variable "sonarqube_database_name" {
  description   = "SonarQube database name"
  type          = string
  sensitive     = true
}

variable "sonarqube_database_username" {
  description   = "SonarQube database username"
  type          = string
  sensitive     = true
}

variable "sonarqube_database_password" {
  description   = "SonarQube database password"
  type          = string
  sensitive     = true
}

variable "sonarqube_current_admin_password" {
  description   = "SonarQube current default password"
  type          = string
  sensitive     = true
}

variable "sonarqube_admin_password" {
  description   = "SonarQube changed password"
  type          = string
  sensitive     = true
}
