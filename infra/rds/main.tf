module "rds" {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-rds.git?ref=3ba7984d024e035f7b604b1f96726e6bc527e80d"   # commit hash for version 6.7.0
#   source = "terraform-aws-modules/rds/aws"
#   version = "6.7.0"

  identifier = var.rds_name

  port                  = var.database_port
  engine                = var.database_engine
  engine_version        = var.database_engine_version
  instance_class        = var.database_instance_class
  storage_type          = var.database_storage_type # "gp2"
  allocated_storage     = var.database_storage_size
  max_allocated_storage = var.database_max_storage_size

  db_name   = var.database_name
  username  = var.database_username
  password  = var.database_password

#   db_name   = aws_ssm_parameter.database_name.value
#   username  = aws_ssm_parameter.database_username.value
#   password  = aws_ssm_parameter.database_password.value
#   iam_database_authentication_enabled = true

  manage_master_user_password =false

  storage_encrypted = true
  kms_key_id = aws_kms_key.database_encrypt_key.arn

  maintenance_window = var.database_maintenance_window
  backup_window      = var.database_backup_window

#   monitoring_interval    = "30"
#   monitoring_role_name   = "GreenCityRDSMonitoringRole"
#   create_monitoring_role = true

#   create_cloudwatch_log_group = true
  enabled_cloudwatch_logs_exports = var.database_cloudwatch_logs_exports

  create_db_option_group    = false
  create_db_parameter_group = false

  # DB subnet group
  create_db_subnet_group = false
  db_subnet_group_name   = var.database_subnet_group # module.vpc.database_subnet_group
#   subnet_ids             = [module.vpc.database_subnets]

  vpc_security_group_ids = [ aws_security_group.database.id ]

  # Database Deletion Protection
  deletion_protection = false # true
  skip_final_snapshot = true

  backup_retention_period = 10

  tags = {
    Name        = join("_", [var.project_name, "_rds"])
    Terraform   = "true"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "database" {
  name        = join("_", [var.project_name, "_db_security_group"])
  description = "Demo security group for database"
  vpc_id      =  var.vpc_id # module.vpc.vpc_id

  tags = {
    Name        = join("_", [var.project_name, "_database_sg"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}

resource "aws_security_group_rule" "database_allow_inbound_from_appserver" {
  type                     = "ingress"
  description              = "PostgreSQL ingress"
  from_port                = module.rds.db_instance_port
  to_port                  = module.rds.db_instance_port
  protocol                 = "tcp"

  source_security_group_id = var.eks_worker_nodes_security_group_id # module.custom_eks.eks_worker_nodes_security_group_id
  security_group_id        = aws_security_group.database.id
}

resource "aws_kms_key" "database_encrypt_key" {
  description             = "A key to encrypt database"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  tags = {
    Name        = join("_", [var.project_name, "_database_encrypt_key"])
    terraform   = "true"
    environment = var.environment
    project     = var.project_name
  }
}
