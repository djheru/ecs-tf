module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.app_name}-db"

  engine               = "postgres"
  engine_version       = "13"
  family               = "postgres13"
  major_engine_version = "13"
  instance_class       = "db.t3.small"

  allocated_storage     = 20
  max_allocated_storage = 100

  db_name                     = "${replace(var.app_name, "-", "_")}_db"
  username                    = replace(var.app_name, "-", "_")
  port                        = 5432
  manage_master_user_password = true

  multi_az               = true
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  subnet_ids             = module.vpc.database_subnets
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = true

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60
  monitoring_role_name                  = "${var.app_name}-monitoring-role"
  monitoring_role_use_name_prefix       = true

  parameters = [
    {
      name  = "autovacuum"
      value = 1
    },
    {
      name  = "client_encoding"
      value = "utf8"
    }
  ]
}

resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "${var.app_name}-db-subnet-group"
  subnet_ids = module.vpc.database_subnets
}

