variable "aws_region" {
  description   = "AWS region"
  type          = string
  default       = "us-east-1"
}

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