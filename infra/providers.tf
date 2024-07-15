terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.54"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }

    # kubectl = {
    #   source  = "gavinbunney/kubectl"
    #   version = ">= 1.7.0"
    # }

    helm = {
      source = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
#   host                   = module.custom_eks.cluster_endpoint # data.aws_eks_cluster.default.endpoint
#   cluster_ca_certificate = base64decode(module.custom_eks.cluster_certificate_authority_data)
#   host                   = data.aws_eks_cluster.default.endpoint
  host                   = module.custom_eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.custom_eks.certificate_authority_data)
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
#   load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.aws_region]
    # args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id]  #, "--region", var.aws_region] # module.custom_eks.cluster_name] # data.aws_eks_cluster.default.id] #, "--profile", "eks-admin" ]
    command     = "aws"
  }
}

# provider "kubectl" {
#   host                   = data.aws_eks_cluster.default.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
# #   token                  = data.aws_eks_cluster_auth.main.token
#   load_config_file       = false

#   exec {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id] # module.custom_eks.cluster_name] #var.eks_cluster_name] # data.aws_eks_cluster.default.id] #, "--profile", "eks-admin"]
#       command     = "aws"
#     }
# }

provider "helm" {
  kubernetes {
	# config_path = "~/.kube/config"
    # host                   = module.custom_eks.cluster_endpoint # data.aws_eks_cluster.default.endpoint
    # cluster_ca_certificate = base64decode(module.custom_eks.cluster_certificate_authority_data)
    # host                   = data.aws_eks_cluster.default.endpoint
    host                   = module.custom_eks.cluster_endpoint
    # cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)
    cluster_ca_certificate = base64decode(module.custom_eks.certificate_authority_data)
    
  exec {
      api_version = "client.authentication.k8s.io/v1beta1"
    #   args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id, "--region", var.aws_region] # module.custom_eks.cluster_name] #var.eks_cluster_name] # data.aws_eks_cluster.default.id] #, "--profile", "eks-admin"]
      args        = ["eks", "get-token", "--cluster-name", var.eks_cluster_name, "--region", var.aws_region] # module.custom_eks.cluster_name] #var.eks_cluster_name] # data.aws_eks_cluster.default.id] #, "--profile", "eks-admin"]
      command     = "aws"
    }
  }
}
