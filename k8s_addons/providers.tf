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
  }
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.default.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id, "--region", var.aws_region] #, "--profile", "eks-admin" ]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.default.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.default.certificate_authority[0].data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.default.id, "--region", var.aws_region] #, "--profile", "eks-admin"]
      command     = "aws"
    }
  }
}