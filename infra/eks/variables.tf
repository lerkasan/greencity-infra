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
  default       = "AL2023_x86_64_STANDARD"  # "AL2023_x86_64_STANDARD"  or "AL2_x86_64"
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

# variable "k8s_namespaces" {
#   description   = "k8s namespaces"
#   type          = list(string)
#   default       = []
# }

variable "vpc_id" {
  description   = "VPC id"
  type          = string
  default       = ""
}

variable "vpc_private_subnet_ids" {
  description   = "private subnet ids"
  type          = list(string)
  default       = []
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
