data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.app_name}-vpc"
  cidr = var.vpc_cidr

  azs                          = var.vpc_azs
  private_subnets              = var.private_subnets
  public_subnets               = var.public_subnets
  database_subnets             = var.database_subnets
  create_database_subnet_group = true

  create_igw             = true
  enable_nat_gateway     = true
  create_egress_only_igw = true
  single_nat_gateway     = true

  tags = {
    Name            = "${var.app_name}-vpc"
    ApplicationName = var.app_name
  }
}
