# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2009
# https://github.com/terraform-aws-modules/terraform-aws-eks/issues/2525#issuecomment-1670484992
# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1720#issuecomment-1453738911
# data "aws_eks_cluster" "default" {
#   name = module.eks.cluster_name
#   depends_on = [ module.eks.eks_managed_node_groups ]
# }

# data "aws_eks_cluster_auth" "default" {
#   name = module.eks.cluster_name
#   depends_on = [ module.eks.eks_managed_node_groups ]
# }

module "vpc" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git?ref=25322b6b6be69db6cca7f167d7b0e5327156a595" # commit hash for version 5.8.1
  #   source  = "terraform-aws-modules/vpc/aws"
  #   version = "5.8.1"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs              = var.availability_zones
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }


  create_database_subnet_group    = true
  create_elasticache_subnet_group = false
  create_redshift_subnet_group    = false

  enable_nat_gateway     = true
  single_nat_gateway     = true  #
  one_nat_gateway_per_az = false #

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = join("_", [var.project_name, "_vpc"])
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

# module "custom_ecr" {
#   source = "./ecr"

#   ecr_repository_names = var.ecr_repository_names
#   ecr_repository_type = var.ecr_repository_type
#   ecr_repository_scan_type = var.ecr_repository_scan_type
#   ecr_images_limit = var.ecr_images_limit
#   ecr_user_name = var.ecr_user_name
#   aws_region = var.aws_region
#   project_name = var.project_name
#   environment = var.environment
# }

module "custom_eks" {
  source = "./eks"

  eks_cluster_name        = var.eks_cluster_name
  eks_cluster_version     = var.eks_cluster_version
  eks_node_ami_type       = var.eks_node_ami_type
  eks_node_disk_size      = var.eks_node_disk_size
  eks_node_instance_types = var.eks_node_instance_types
  eks_node_groups_config  = var.eks_node_groups_config
  eks_admin_iamrole_name  = var.eks_admin_iamrole_name
  vpc_id                  = module.vpc.vpc_id
  vpc_private_subnet_ids  = module.vpc.private_subnets
  project_name            = var.project_name
  environment             = var.environment
}

module "greencity_rds" {
  source                             = "./rds"
  rds_name                           = var.greencity_rds_name
  vpc_id                             = module.vpc.vpc_id
  database_name                      = var.greencity_database_name
  database_username                  = var.greencity_database_username
  database_password                  = var.greencity_database_password
  database_engine                    = var.database_engine
  database_engine_version            = var.database_engine_version
  database_port                      = var.database_port
  database_instance_class            = var.database_instance_class
  database_storage_type              = var.database_storage_type
  database_storage_size              = var.database_storage_size
  database_max_storage_size          = var.database_max_storage_size
  database_maintenance_window        = var.database_maintenance_window
  database_backup_window             = var.database_backup_window
  database_subnet_group              = module.vpc.database_subnet_group
  database_cloudwatch_logs_exports   = var.database_cloudwatch_logs_exports
  eks_worker_nodes_security_group_id = module.custom_eks.eks_worker_nodes_security_group_id
  project_name                       = var.project_name
  environment                        = var.environment
}

module "sonarqube_rds" {
  source                             = "./rds"
  rds_name                           = var.sonarqube_rds_name
  vpc_id                             = module.vpc.vpc_id
  database_name                      = var.sonarqube_database_name
  database_username                  = var.sonarqube_database_username
  database_password                  = var.sonarqube_database_password
  database_engine                    = var.database_engine
  database_engine_version            = var.database_engine_version
  database_port                      = var.database_port
  database_instance_class            = var.database_instance_class
  database_storage_type              = var.database_storage_type
  database_storage_size              = var.database_storage_size
  database_max_storage_size          = var.database_max_storage_size
  database_maintenance_window        = var.database_maintenance_window
  database_backup_window             = var.database_backup_window
  database_subnet_group              = module.vpc.database_subnet_group
  database_cloudwatch_logs_exports   = var.database_cloudwatch_logs_exports
  eks_worker_nodes_security_group_id = module.custom_eks.eks_worker_nodes_security_group_id
  project_name                       = "greencity_sonarqube"
  environment                        = var.environment
}

resource "aws_kms_key" "ssm_param_encrypt_key" {
  description             = "A key to encrypt SSM parameters"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = join("_", [var.project_name, "_ssm_param_encrypt_key"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "database_host" {
  name        = join("_", [var.project_name, "database_host"])
  description = "Demo database host"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = module.greencity_rds.db_instance_address

  tags = {
    Name        = join("_", [var.project_name, "database_host"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "database_name" {
  name        = join("_", [var.project_name, "database_name"])
  description = "Demo database name"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.greencity_database_name

  tags = {
    Name        = join("_", [var.project_name, "database_name"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "database_username" {
  name        = join("_", [var.project_name, "database_username"])
  description = "Demo database username"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.greencity_database_username

  tags = {
    Name        = join("_", [var.project_name, "database_username"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "database_password" {
  name        = join("_", [var.project_name, "database_password"])
  description = "Demo database password"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.greencity_database_password

  tags = {
    Name        = join("_", [var.project_name, "database_password"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "api_key" {
  name        = join("_", [var.project_name, "api_key"])
  description = "Greencity API key"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.api_key

  tags = {
    Name        = join("_", [var.project_name, "api_key"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "api_secret" {
  name        = join("_", [var.project_name, "api_secret"])
  description = "Greencity API secret"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.api_secret

  tags = {
    Name        = join("_", [var.project_name, "api_secret"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "azure_connection_string" {
  name        = join("_", [var.project_name, "azure_connection_string"])
  description = "Greencity Azure connection string"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.azure_connection_string

  tags = {
    Name        = join("_", [var.project_name, "azure_connection_string"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "email_address" {
  name        = join("_", [var.project_name, "email_address"])
  description = "Greencity email address"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.email_address

  tags = {
    Name        = join("_", [var.project_name, "email_address"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "email_password" {
  name        = join("_", [var.project_name, "email_password"])
  description = "Greencity email password"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.email_password

  tags = {
    Name        = join("_", [var.project_name, "email password"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "google_api_key" {
  name        = join("_", [var.project_name, "google_api_key"])
  description = "Greencity API key"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.google_api_key

  tags = {
    Name        = join("_", [var.project_name, "google_api_key"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "google_client_id" {
  name        = join("_", [var.project_name, "google_client_id"])
  description = "Greencity client id"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.google_client_id

  tags = {
    Name        = join("_", [var.project_name, "google_client_id"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "google_client_id_manager" {
  name        = join("_", [var.project_name, "google_client_id_manager"])
  description = "Greencity client id manager"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.google_client_id_manager

  tags = {
    Name        = join("_", [var.project_name, "google_client_id_manager"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "token_key" {
  name        = join("_", [var.project_name, "token_key"])
  description = "Greencity token key"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.token_key

  tags = {
    Name        = join("_", [var.project_name, "token_key"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "google_creds_json" {
  name        = join("_", [var.project_name, "google_creds_json"])
  description = "Greencity google-creds json"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  #   value       = file("${path.module}/../../secrets/backend/google-creds.json")
  value = var.google_creds_json

  tags = {
    Name        = join("_", [var.project_name, "google_creds_json"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "argocd_repo_url" {
  name        = join("_", [var.project_name, "helm_repo_url"])
  description = "Greencity Helm repo url for ArgoCD"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.helm_repo_url

  tags = {
    Name        = join("_", [var.project_name, "helm_repo_url"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "argocd_repo_username" {
  name        = join("_", [var.project_name, "helm_repo_username"])
  description = "Greencity Helm repo user for ArgoCD"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.helm_repo_username

  tags = {
    Name        = join("_", [var.project_name, "helm_repo_username"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_ssm_parameter" "argocd_repo_password" {
  name        = join("_", [var.project_name, "helm_repo_password"])
  description = "Greencity Helm repo password for ArgoCD"
  type        = "SecureString"
  key_id      = aws_kms_key.ssm_param_encrypt_key.id
  value       = var.helm_repo_password

  tags = {
    Name        = join("_", [var.project_name, "helm_repo_password"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

# resource "aws_ssm_parameter" "params" {
#   for_each = var.ssm_parameters

#   name        = join("_", [var.project_name, each.key ])
#   description = each.key 
#   type        = "SecureString"
#   key_id      = aws_kms_key.ssm_param_encrypt_key.id
#   value       = each.value

#   tags = {
#     Name        = join("_", [var.project_name, each.key])
#     terraform   = "true"
#     environment = var.environment
#     project     = var.project_name
#   }
# }

module "eks_extra" {
  source = "./eks_extra"

  cluster_name      = var.eks_cluster_name
  k8s_namespaces    = var.k8s_namespaces
  domain_name       = var.domain_name
  oidc_provider_arn = module.custom_eks.oidc_provider_arn
  parameter_arns = [
    aws_ssm_parameter.database_host.arn,
    aws_ssm_parameter.database_name.arn,
    aws_ssm_parameter.database_username.arn,
    aws_ssm_parameter.database_password.arn,
    aws_ssm_parameter.google_creds_json.arn,
    aws_ssm_parameter.api_key.arn,
    aws_ssm_parameter.api_secret.arn,
    aws_ssm_parameter.azure_connection_string.arn,
    aws_ssm_parameter.email_address.arn,
    aws_ssm_parameter.email_password.arn,
    aws_ssm_parameter.google_api_key.arn,
    aws_ssm_parameter.google_client_id.arn,
    aws_ssm_parameter.google_client_id_manager.arn,
    aws_ssm_parameter.token_key.arn,
    aws_ssm_parameter.argocd_repo_url.arn,
    aws_ssm_parameter.argocd_repo_username.arn,
    aws_ssm_parameter.argocd_repo_password.arn
  ]
  kms_key_arns = [aws_kms_key.ssm_param_encrypt_key.arn]

  datadog_api_key = var.datadog_api_key
  datadog_site    = var.datadog_site

  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password

  sonarqube_db_instance_address    = module.sonarqube_rds.db_instance_address
  sonarqube_database_name          = var.sonarqube_database_name
  sonarqube_database_username      = var.sonarqube_database_username
  sonarqube_database_password      = var.sonarqube_database_password
  sonarqube_current_admin_password = var.sonarqube_current_admin_password
  sonarqube_admin_password         = var.sonarqube_admin_password

  depends_on = [module.custom_eks]
  #   depends_on = [ module.custom_eks.eks_managed_node_groups ]
}
