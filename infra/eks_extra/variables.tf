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
  default       = ""
  sensitive     = true
}

variable "datadog_site" {
  description   = "Datadog site"
  type          = string
  default       = ""
  sensitive     = true
}

variable "grafana_admin_user" {
  description   = "Grafana admin user"
  type          = string
  default       = ""
  sensitive     = true
}

variable "grafana_admin_password" {
  description   = "Grafana admin password"
  type          = string
  default       = ""
  sensitive     = true
}

variable "sonarqube_db_instance_address" {
  description   = "SonarQube DB instance address"
  type          = string
  default       = ""
  sensitive     = true
}

variable "sonarqube_database_name" {
  description   = "SonarQube database name"
  type          = string
  default       = ""
  sensitive     = true
}

variable "sonarqube_database_username" {
  description   = "SonarQube database username"
  type          = string
  default       = ""
  sensitive     = true
}

variable "sonarqube_database_password" {
  description   = "SonarQube database password"
  type          = string
  default       = ""
  sensitive     = true
}

# variable "sonarqube_domain_name" {
#   description   = "SonarQube domain name"
#   type          = string
#   default       = ""
# }

# variable "sonarqube_ssl_certificate_arn" {
#   description   = "SonarQube SSL certificate ARN"
#   type          = string
#   default       = ""
# }


variable "artifactory_database_password" {
  description   = "Artifactory database password"
  type          = string
  default       = ""
  sensitive     = true
}


# variable "nexus_db_instance_address" {
#   description   = "Nexus DB instance address"
#   type          = string
#   default       = ""
#   sensitive     = true
# }

# variable "nexus_database_name" {
#   description   = "Nexus database name"
#   type          = string
#   default       = ""
#   sensitive     = true
# }

# variable "nexus_database_username" {
#   description   = "Nexus database username"
#   type          = string
#   default       = ""
#   sensitive     = true
# }

# variable "nexus_database_password" {
#   description   = "Nexus database password"
#   type          = string
#   default       = ""
#   sensitive     = true
# }

# variable "nexus_ui_password" {
#   description   = "Nexus UI password"
#   type          = string
#   default       = ""
#   sensitive     = true
# }

variable "artifactory_domain_name" {
  description   = "Nexus domain name"
  type          = string
  default       = ""
}

variable "artifactory_ssl_certificate_arn" {
  description   = "nexus SSL Certificate ARN"
  type          = string
  default       = ""
}