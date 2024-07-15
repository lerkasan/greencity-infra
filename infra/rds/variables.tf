variable "rds_name" {
  description = "The name of the RDS instance"
  type        = string
  default     = "greencity-database"
}

variable "database_name" {
  description = "Database name variable passed through a file secrets.tfvars or an environment variable TF_database_name"
  type        = string
  sensitive   = true
}

variable "database_username" {
  description = "Database username variable passed through a file secrets.tfvars or environment variable TF_database_username"
  type        = string
  sensitive   = true
}

variable "database_password" {
  description = "Database password variable passed through a file secrets.tfvars or environment variable TF_database_password"
  type        = string
  sensitive   = true
}

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

variable "database_subnet_group" {
  description   = "database subnet group"
  type          = string
  default       = ""
}

variable "vpc_id" {
  description   = "VPC id"
  type          = string
  default       = ""
}

variable "eks_worker_nodes_security_group_id" {
  description   = "EKS worker nodes security group id"
  type          = string
  default       = ""
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
