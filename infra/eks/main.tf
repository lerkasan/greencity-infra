data "aws_caller_identity" "current" {}

module "eks" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=d7aea4ca6b7d5fa08c70bf67fa5e9e5c514d26d2"   # commit hash for version 20.17.2
#   source  = "terraform-aws-modules/eks/aws"
#   version = "20.17.2"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_cluster_version

  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  enable_cluster_creator_admin_permissions = true

  vpc_id     = var.vpc_id
  subnet_ids = var.vpc_private_subnet_ids

  enable_irsa = true

  eks_managed_node_group_defaults = {
    ami_type               = var.eks_node_ami_type
    disk_size              = var.eks_node_disk_size
    instance_types         = var.eks_node_instance_types
    vpc_security_group_ids = [ aws_security_group.eks_worker_nodes.id ]
  }

  eks_managed_node_groups = var.eks_node_groups_config

  cluster_addons = {
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
  }

  tags = {
    Name        = join("_", [var.project_name, "_eks"])
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

module "eks_auth" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//modules/aws-auth?ref=17448b4782b785403a395f96e1b5520e78f14529"   # commit hash for version 20.15.0
#   source  = "terraform-aws-modules/eks/aws//modules/aws-auth"
#   version = "20.15.0"

  manage_aws_auth_configmap = true

  aws_auth_roles = [
    {
      rolearn  = module.eks_admins_iam_role.iam_role_arn
      username = module.eks_admins_iam_role.iam_role_name
      groups   = ["system:masters"]
    }
  ]

  depends_on = [ module.eks.cluster_name ]
}

module "allow_eks_access_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.39.1"

  name          = "allow-eks-access"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
          "ec2:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

module "eks_admins_iam_role" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "5.39.1"

  role_name         = var.eks_admin_iamrole_name # "eks-admin"
  create_role       = true
  role_requires_mfa = false

  custom_role_policy_arns = [module.allow_eks_access_iam_policy.arn]

  trusted_role_arns = [
    "arn:aws:iam::${data.aws_caller_identity.current.id}:root"  # ${module.vpc.vpc_owner_id}
  ]
}

module "allow_assume_eks_admins_iam_policy" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-policy"
#   version = "5.39.1"

  name          = "allow-assume-eks-admin-iam-role"
  create_policy = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
        ]
        Effect   = "Allow"
        Resource = module.eks_admins_iam_role.iam_role_arn
      },
    ]
  })
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role-with-oidc?ref=de95e21a3bc51cd3a44b3b95a4c2f61000649ebb"   # commit hash for version 5.39.1
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
#   version = "5.39.1"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

resource "aws_security_group" "eks_worker_nodes" {
  name        = join("_", [var.project_name, "_eks_worker_node_security_group"])
  description = "security group for EKS worker node"
  vpc_id      = var.vpc_id

  tags = {
    Name        = join("_", [var.project_name, "_eks_worker_node_sg"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_security_group_rule" "allow_local_traffic_to_eks_workers" {
  description       = "allow inbound traffic to eks workers"
  from_port         = 0
  protocol          = "-1"
  to_port           = 0
  security_group_id = aws_security_group.eks_worker_nodes.id
  type              = "ingress"
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
}

resource "aws_security_group_rule" "allow_traffic_from_eks_workers" {
  description       = "allow outbound traffic from eks workers to anywhere"
  from_port         = 0
  protocol          = "-1"
  security_group_id = aws_security_group.eks_worker_nodes.id
  to_port           = 0
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
}
