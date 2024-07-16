aws_region           = "us-east-1"
state_s3_bucket_name = "greencity-terraform-state"

project_name         = "greencity"
environment          = "prod"

vpc_name = "greencity"
vpc_cidr = "10.0.0.0/16"
public_subnets      = ["10.0.10.0/24", "10.0.11.0/24"]
private_subnets     = ["10.0.20.0/24", "10.0.22.0/24"]
database_subnets    = ["10.0.30.0/24", "10.0.33.0/24"]
availability_zones  = ["us-east-1a", "us-east-1b"]

ecr_repository_names = [ 
  "greencity/backcore", 
  "greencity/backuser", 
  "greencity/frontend",
  "greencity-backcore",
  "greencity-backuser",
  "greencity-frontend"
]

ecr_repository_type = "private"
ecr_repository_scan_type = "BASIC"
ecr_images_limit = 5
ecr_user_name = "greencity-ecr-push"

eks_cluster_name = "greencity-eks"
eks_cluster_version = "1.30" # "1.29"
eks_node_ami_type = "AL2023_x86_64_STANDARD"    # "AL2023_x86_64_STANDARD"  or "AL2_x86_64"
eks_node_disk_size = 20
eks_node_instance_types = [ "t3.medium", "t3.small" ]
eks_admin_iamrole_name = "eks-admin"
k8s_namespaces = [ "greencity", "monitoring", "kube-dashboard", "argocd", "sonarqube" ]

eks_node_groups_config = { 
  one = {
    desired_size = 5
    min_size     = 1
    max_size     = 8

    labels = {
      role = "general"
    }

    instance_types = [ "t3.medium", "t3.small" ]
    capacity_type  = "ON_DEMAND"
  }

  two = {
    desired_size = 5
    min_size     = 1
    max_size     = 8

    labels = {
      role = "general"
    }

    instance_types = [ "t3.medium", "t3.small" ]
    capacity_type  = "ON_DEMAND"
  }
}

greencity_rds_name = "greencity"
sonarqube_rds_name = "sonar"
# nexus_rds_name = "nexus"

# sonarqube_domain_name = "sonar.lerkasan.net"
# sonarqube_ssl_certificate_arn = "arn:aws:acm:us-east-1:084912621610:certificate/feef84f4-f358-4ccb-88e1-a5d24ebd1da6"
artifactory_domain_name = "artifactory.lerkasan.net"
artifactory_ssl_certificate_arn = "arn:aws:acm:us-east-1:084912621610:certificate/062578ed-1924-40d6-ba48-8e2bc3444e14"
database_engine = "postgres"
database_engine_version = "16"
database_port = 5432
database_instance_class = "db.t3.micro"
database_storage_type = "gp2"
database_storage_size = 5
database_max_storage_size = 10
database_maintenance_window = "Sun:02:00-Sun:04:00"
database_backup_window = "00:30-02:00"
database_cloudwatch_logs_exports = [ "postgresql" ]

datadog_site = "datadoghq.com"
helm_repo_url = "https://github.com/lerkasan/greencity-helm"