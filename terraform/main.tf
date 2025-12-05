# Main Terraform configuration for AWS infrastructure

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }

  # backend "s3" {
  #   # Update these values according to your setup
  #   bucket = "oxigon-terraform-eks-state-s3-bucket"
  #   key    = "java-app/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  environment     = var.environment
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  azs             = var.availability_zones
}

# VPC Module
module "vpc_bastion" {
  source                 = "./modules/vpc_bastion"
  environment            = var.environment
  vpc_cidr_bastion       = var.vpc_cidr_bastion
  public_subnets_bastion = [var.public_subnets_bastion[0]]
  azs                    = [var.availability_zones[0]]
}


# Security Module
module "security" {
  source           = "./modules/security"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  vpc_id_bastion   = module.vpc_bastion.vpc_id_bastion
  vpc_cidr_bastion = module.vpc_bastion.vpc_cidr_bastion
  vpc_cidr         = var.vpc_cidr
  depends_on       = [module.vpc]
}

# VPC Peering 
resource "aws_vpc_peering_connection" "bastion_to_main" {
  vpc_id      = module.vpc_bastion.vpc_id_bastion
  peer_vpc_id = module.vpc.vpc_id
  auto_accept = true

  tags = {
    Name = "${var.environment}-bastion-to-main"
  }
}

resource "aws_route" "bastion_to_app" {
  route_table_id            = module.vpc_bastion.public_route_table_id
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_main.id
  depends_on                = [aws_vpc_peering_connection.bastion_to_main]
}

resource "aws_route" "app_to_bastion" {
  route_table_id            = module.vpc.private_route_table_id
  destination_cidr_block    = var.vpc_cidr_bastion
  vpc_peering_connection_id = aws_vpc_peering_connection.bastion_to_main.id
  depends_on                = [aws_vpc_peering_connection.bastion_to_main]
}



# RDS Module

# module "rds" {
#   source      = "./modules/rds"
#   environment = var.environment
#   # vpc_id = module.vpc.vpc_cidr
#   db-name      = var.db_name
#   rds-username = var.db_username
#   rds-name     = var.db_name
#   sg-name      = var.sg-name
#   # private-subnet-name1=var.private_subnets[0]
#   rds-pwd = var.db_password

#   depends_on = [module.security]

# }

module "ec2" {
  source                = "./modules/ec2"
  ami                   = var.ami
  instance_type         = var.instance_type
  environment           = var.environment
  subnet_id             = module.vpc.private_subnet_ids[0]
  iam-policy            = var.iam-policy
  iam-role              = var.iam-role
  instance-profile-name = var.instance-profile-name
  db_username           = var.db_username
  db_password           = var.db_password

  depends_on = [module.security]


}

module "ec2_bastion" {
  source        = "./modules/ec2_bastion"
  ami           = var.ami
  instance_type = var.bastion_instance_type
  environment   = var.environment
  subnet_id     = module.vpc_bastion.public_subnet_ids

  depends_on = [module.security]

}
# module "rds" {
#   source = "./modules/rds"

#   environment        = var.environment
#   vpc_id             = module.vpc.vpc_cidr.id
#   subnet_ids         = module.vpc.private_subnet_ids
#   security_group_ids = [module.security.db_security_group_id]
#   db_name            = var.db_name
#   db_username        = var.db_username
#   db_password        = var.db_password
# }

# Application Load Balancer Module
module "alb" {
  source      = "./modules/alb"
  alb-name    = var.alb-name
  tg-name     = var.tg-name
  environment = var.environment
  instance_id = module.ec2.instance_id

  depends_on = [module.security]
}

# Auto Scaling Group Module
# module "asg" {
#   source = "./modules/asg"

#   environment         = var.environment
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   security_group_ids = [module.security.app_security_group_id]
#   target_group_arns  = [module.alb.target_group_arn]
#   instance_type      = var.instance_type
#   key_name           = var.key_name
#   min_size          = var.asg_min_size
#   max_size          = var.asg_max_size
#   desired_capacity  = var.asg_desired_capacity
# }

# CloudWatch Module
# module "monitoring" {
#   source = "./modules/monitoring"

#   environment = var.environment
#   rds_instance_id = module.rds.rds_instance_id
#   asg_name = module.asg.asg_name
# } 
