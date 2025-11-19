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

############################################
# Resource Group
############################################
resource "azurerm_resource_group" "rg" {
  name     = "${local.env}-notesapp-rg"
  location = var.location
}

############################################
# Frontend Container App
############################################
module "frontend" {
  source = "../../modules/azure-container-app"

  env      = local.env
  name     = "frontend"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name

  image = var.frontend_image
  port  = 80

  vnet_cidr   = var.vnet_cidr
  subnet_cidr = var.frontend_subnet_cidr

  external_ingress = true
  internal_lb      = false

  docker_registry_server   = var.registry_server
  docker_registry_username = var.registry_username
  docker_registry_password = var.registry_password

  min_replicas = 1
  max_replicas = 3
}

############################################
# Backend Container App
############################################
module "backend" {
  source = "../../modules/azure-container-app"

  env      = local.env
  name     = "backend"
  location = var.location
  resource_group_name = azurerm_resource_group.rg.name

  image = var.backend_image
  port  = 5000

  vnet_cidr   = var.vnet_cidr
  subnet_cidr = var.backend_subnet_cidr

  external_ingress = false   # internal only
  internal_lb      = true

  docker_registry_server   = var.registry_server
  docker_registry_username = var.registry_username
  docker_registry_password = var.registry_password

  min_replicas = 1
  max_replicas = 3

  environment_variables = {
    DB_HOST     = azurerm_mysql_flexible_server.notes.fqdn
    DB_USERNAME = var.db_username
    DB_PASSWORD = var.db_password
    DB_NAME     = var.db_name
  }
}

############################################
# MySQL Flexible Server
############################################
resource "azurerm_mysql_flexible_server" "notes" {
  name                   = "notes-db-${local.env}"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = var.location
  administrator_login    = var.db_username
  administrator_password = var.db_password
  sku_name               = "B_Gen5_1"
  storage_mb             = 5120
  version                = "8.0"
  delegated_subnet_id    = module.backend.subnet_id
  public_network_access_enabled = false
}


