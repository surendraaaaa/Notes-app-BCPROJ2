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

locals {
  env = "dev"
}


module "network" {
  source = "../../modules/aws-network"
  env = local.env
  vpc_cidr = "10.0.0.0/16"
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
}

module "alb" {
  source = "../../modules/aws-alb"
  env    = local.env
  vpc_id = module.network.vpc_id
  subnets = module.network.public_subnets
}

module "frontend" {
  source = "../../modules/aws-ecs-service"

  env    = local.env
  region = var.region

  name   = "frontend"
  image  = var.frontend_image

  cpu    = 256
  memory = 512
  port   = 80
  replicas = 1

  subnets         = module.network.public_subnets
  security_groups = []
  target_group_arn = module.alb.frontend_tg_arn
}

module "backend" {
  source = "../../modules/aws-ecs-service"

  env    = local.env
  region = var.region

  name   = "backend"
  image  = var.backend_image

  cpu    = 256
  memory = 512
  port   = 8080
  replicas = 1

  subnets         = module.network.public_subnets
  security_groups = []
  target_group_arn = module.alb.backend_tg_arn
}

output "alb_dns" {
  value = module.alb.alb_dns
}
