variable "aws_region" {
  description   = "AWS region"
  type          = string
  default       = "us-east-1"
}

variable "project_name" {
  description   = "Project name"
  type          = string
  default       = "greencity"
}

variable "environment" {
  description   = "Environment: dev/stage/prod"
  type          = string
  default       = "prod"
}

variable "state_s3_bucket_name" {
  description   = "Terraform state S3 bucket"
  type          = string
  default       = "greencity-terraform-state"
}

# -------------- Network parameters ----------------

variable "availability_zones" {
  description   = "availability zones"
  type          = list(string)
  default       = ["us-east-1a", "us-east-1b"]
}

variable "vpc_name" {
  description   = "VPC name"
  type          = string
  default       = ""
}

variable "vpc_cidr" {
  description   = "VPC CIDR"
  type          = string
  default       = "10.0.0.0/16"
}

variable "public_subnets" {
  description   = "public subnets"
  type          = list(string)
  default       = ["10.0.10.0/24", "10.0.10.0/24"]
}

variable "private_subnets" {
  description   = "private subnets"
  type          = list(string)
  default       = ["10.0.20.0/24", "10.0.20.0/24"]
}

variable "database_subnets" {
  description   = "database subnets"
  type          = list(string)
  default       = ["10.0.30.0/24", "10.0.30.0/24"]
}

variable "domain_name" {
  description   = "Domain name"
  type          = string
  default       = "lerkasan.net"
}


# -------------- ECR parameters --------------------

variable "ecr_repository_names" {
  description   = "ECR repository names"
  type          = list(string)
  default       = []
}

variable "ecr_repository_type" {
  description   = "ECR repository type"
  type          = string
  default       = "private"
}

variable "ecr_repository_scan_type" {
  description   = "ecr_repository_scan_type (BASIC or ENHANCED)"
  type          = string
  default       = "BASIC"
}

variable "ecr_images_limit" {
  description   = "Number of images to keep in an ECR repository"
  type          = number
  default       = 5
}

variable "ecr_user_name" {
  description   = "A name of a use with access to ECR"
  type          = string
  default       = "" # "greencity-ecr-push"
}

# -------------- Database parameters ---------------

variable "greencity_rds_name" {
  description = "The name of the RDS instance"
  type        = string
  default     = "greencity-database"
}

variable "greencity_database_name" {
  description = "Database name variable passed through a file secrets.tfvars or an environment variable TF_database_name"
  type        = string
  sensitive   = true
}

variable "greencity_database_username" {
  description = "Database username variable passed through a file secrets.tfvars or environment variable TF_database_username"
  type        = string
  sensitive   = true
}

variable "greencity_database_password" {
  description = "Database password variable passed through a file secrets.tfvars or environment variable TF_database_password"
  type        = string
  sensitive   = true
}

variable "sonarqube_rds_name" {
  description = "The name of the RDS instance"
  type        = string
  default     = "greencity-database"
}

variable "sonarqube_database_name" {
  description = "Database name variable passed through a file secrets.tfvars or an environment variable TF_database_name"
  type        = string
  sensitive   = true
}

variable "sonarqube_database_username" {
  description = "Database username variable passed through a file secrets.tfvars or environment variable TF_database_username"
  type        = string
  sensitive   = true
}

variable "sonarqube_database_password" {
  description = "Database password variable passed through a file secrets.tfvars or environment variable TF_database_password"
  type        = string
  sensitive   = true
}



# variable "nexus_rds_name" {
#   description = "The name of the RDS instance"
#   type        = string
#   default     = "greencity-database"
# }

# variable "nexus_database_name" {
#   description = "Database name variable passed through a file secrets.tfvars or an environment variable TF_database_name"
#   type        = string
#   sensitive   = true
# }

# variable "nexus_database_username" {
#   description = "Database username variable passed through a file secrets.tfvars or environment variable TF_database_username"
#   type        = string
#   sensitive   = true
# }

# variable "nexus_database_password" {
#   description = "Database password variable passed through a file secrets.tfvars or environment variable TF_database_password"
#   type        = string
#   sensitive   = true
# }

# variable "nexus_ui_password" {
#   description = "Nexus UI password variable passed through a file secrets.tfvars or environment variable TF_database_password"
#   type        = string
#   sensitive   = true
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


variable "artifactory_database_password" {
  description   = "Artifactory database password"
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

variable "database_engine" {
  description = "database engine"
  type        = string
  default     = "postgres"
}

variable "database_engine_version" {
  description = "database engine version"
  type        = string
  default     = "16"
}

variable "database_port" {
  description = "database port"
  type        = number
  default     = 5432
}

variable "database_instance_class" {
  description = "database instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "database_storage_type" {
  description = "database storage type"
  type        = string
  default     = "gp2"
}

variable "database_storage_size" {
  description = "database storage size"
  type        = number
  default     = 5
}

variable "database_max_storage_size" {
  description = "database max storage size"
  type        = number
  default     = 10
}

variable "database_maintenance_window" {
  description = "database maintenance window"
  type        = string
  default     = "Sun:02:00-Sun:04:00"
}

variable "database_backup_window" {
  description = "database backup window"
  type        = string
  default     = "00:30-02:00"
}

variable "database_cloudwatch_logs_exports" {
  description = "database maintenance window"
  type        = list(string)
  default     = []
}

# -------------- SSM secrets ---------------

variable "api_key" {
  description = "api key"
  type        = string
  sensitive   = true
}


variable "api_secret" {
  description = "api secret"
  type        = string
  sensitive   = true
}


variable "azure_connection_string" {
  description = "azure connection string"
  type        = string
  sensitive   = true
}


variable "email_address" {
  description = "email address"
  type        = string
  sensitive   = true
}


variable "email_password" {
  description = "email password"
  type        = string
  sensitive   = true
}


variable "google_api_key" {
  description = "google api key"
  type        = string
  sensitive   = true
}

variable "google_client_id" {
  description = "google client id"
  type        = string
  sensitive   = true
}

variable "google_client_id_manager" {
  description = "google client id manager"
  type        = string
  sensitive   = true
}

variable "token_key" {
  description = "token key"
  type        = string
  sensitive   = true
}

variable "google_creds_json" {
  description = "google-creds json"
  type        = string
  sensitive   = true
}

variable "helm_repo_url" {
  description = "helm repo url"
  type        = string
  sensitive   = true
}

variable "helm_repo_username" {
  description = "helm repo username"
  type        = string
  sensitive   = true
}

variable "helm_repo_password" {
  description = "helm repo password"
  type        = string
  sensitive   = true
}


# ------------------ EKS parameters -----------------

variable "eks_cluster_name" {
  description   = "EKS cluster name"
  type          = string
  default       = ""
}

variable "eks_cluster_version" {
  description   = "EKS cluster version"
  type          = string
  default       = "1.29"
}

variable "eks_node_ami_type" {
  description   = "EKS node AMI type"
  type          = string
  default       = "AL2_x86_64"
}

variable "eks_node_disk_size" {
  description   = "EKS node disk size"
  type          = number
  default       = 20
}

variable "eks_node_instance_types" {
  description   = "EKS cluster version"
  type          = list(string)
  default       = [ "t3.medium", "t3.small" ]
}

variable "eks_node_groups_config" {
  type = map(object({
    desired_size   = number,
    min_size       = number,
	max_size       = number,
    labels         = map(string)
	instance_types = list(string)
	capacity_type  = string
  }))
  default = {}
}

variable "eks_admin_iamrole_name" {
  description   = "EKS admin IAM role name"
  type          = string
  default       = "eks-admin"
}

variable "k8s_namespaces" {
  description   = "k8s namespaces"
  type          = list(string)
  default       = []
}

variable "ssm_parameters" {
  type = map(string)
  sensitive = true
  default = {}
}

# -------------- Datadog -----------------

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