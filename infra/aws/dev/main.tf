terraform {
  cloud {
    organization = "mycompany"

    workspaces {
      name = "mycompany-aws-dev"
    }
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

############################################
# AWS Dev Environment - Notes App (3-Tier)
############################################

locals {
  env = "dev"
}

###############################
# Network
###############################
module "network" {
  source = "../../modules/aws-vpc"

  env            = local.env
  vpc_cidr       = var.vpc_cidr
  public_subnets = var.public_subnets
}

###############################
# DB Subnet Group (Private)
##############################
resource "aws_db_subnet_group" "notes" {
  name       = "notes-db-subnet-${local.env}"
  subnet_ids = module.network.private_subnets

  tags = {
    Name        = "notes-db-subnet-${local.env}"
    Environment = local.env
  }
}

##############################
# RDS Instance
##############################
resource "aws_db_instance" "notes" {
  identifier             = "notes-db-${local.env}"
  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  publicly_accessible    = false
  vpc_security_group_ids = [module.sg.ecs_sg_id] # only ECS SG
  db_subnet_group_name   = aws_db_subnet_group.notes.name
  skip_final_snapshot    = true

  backup_retention_period = 7
  storage_encrypted       = true
}

##############################
# Optional Security Group Rule
# Only allow ECS to connect to RDS
##############################
resource "aws_security_group_rule" "ecs_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = module.sg.ecs_sg_id  # DB SG
  source_security_group_id = module.sg.ecs_sg_id  # ECS SG
  description              = "Allow ECS backend to connect to RDS MySQL"
}


###############################
# ALB
###############################
module "alb" {
  source = "../../modules/aws-alb"

  env            = local.env
  name           = "notes-app"
  public_subnets = module.network.public_subnets
  vpc_id         = module.network.vpc_id
  alb_sg         = module.sg.sg_id
  certificate_arn = var.certificate_arn
  deletion_protection = false

  target_groups = {
    frontend = {
      port              = 80
      priority          = 1
      path_patterns     = ["/*"]
      health_check_path = "/"
    }
    backend = {
      port              = 5000
      priority          = 2
      path_patterns     = ["/api/*"]
      health_check_path = "/api/health"
    }
  }
}

###############################
# ECS Cluster + Services
###############################
module "ecs_cluster" {
  source = "../../modules/aws-ecs"

  env               = local.env
  cluster_name      = "notes-app-cluster-${local.env}"
  vpc_id            = module.network.vpc_id
  subnet_ids        = module.network.public_subnets
  security_group_id = module.sg.sg_id

  frontend = {
    service_name     = "frontend"
    container_image  = var.frontend_image
    container_port   = 80
    cpu              = 256
    memory           = 512
    desired_count    = 1
    target_group_arn = module.alb.target_group_arns["frontend"]
    environment = {
      REACT_APP_API_URL = "http://${module.alb.alb_dns_name}/api"
    }
  }

  backend = {
    service_name     = "backend"
    container_image  = var.backend_image
    container_port   = 5000
    cpu              = 256
    memory           = 512
    desired_count    = 1
    target_group_arn = module.alb.target_group_arns["backend"]
    environment = {
      DB_HOST     = aws_db_instance.notes.address
      DB_USERNAME = var.db_username
      DB_PASSWORD = var.db_password
      DB_NAME     = var.db_name
    }
  }
}



