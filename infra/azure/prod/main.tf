terraform {
  cloud {
    organization = "mycompany"

    workspaces {
      name = "mycompany-azure-dev"
    }
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}


locals {
  env = "dev"
}


module "frontend" {
  source = "../../modules/azure-containerapps"

  env            = local.env
  resource_group = var.resource_group
  location       = var.location

  name  = "frontend"
  image = var.frontend_image

  cpu    = 0.5
  memory = 1
  port   = 80
}

module "backend" {
  source = "../../modules/azure-containerapps"

  env            = local.env
  resource_group = var.resource_group
  location       = var.location

  name  = "backend"
  image = var.backend_image

  cpu    = 0.5
  memory = 1
  port   = 8080
}
