############################################
# Resource Group (inherited from parent)
############################################
# The resource group is expected to be passed from the root module

############################################
# Virtual Network & Subnet
############################################
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.env}-${var.name}-vnet"
  address_space       = [var.vnet_cidr]
  location            = var.location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.env}-${var.name}-subnet"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]

  delegations {
    name = "aca-delegation"

    service_delegation {
      name = "Microsoft.Web/containerAppsEnvironments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

############################################
# Log Analytics Workspace
############################################
resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.env}-${var.name}-logs"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

############################################
# Container Apps Environment
############################################
resource "azurerm_container_app_environment" "env" {
  name                        = "${var.env}-${var.name}-env"
  location                    = var.location
  resource_group_name         = var.resource_group_name
  log_analytics_workspace_id  = azurerm_log_analytics_workspace.law.id
  infrastructure_subnet_id    = azurerm_subnet.subnet.id
  internal_load_balancer_enabled = var.internal_lb

  tags = {
    Environment = var.env
  }
}

############################################
# Container App
############################################
resource "azurerm_container_app" "app" {
  name                         = "${var.env}-${var.name}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = azurerm_container_app_environment.env.id
  revision_mode                = "Single"

  ingress {
    external_enabled = var.external_ingress
    target_port      = var.port
    transport        = "auto"
  }

  registry {
    server   = var.docker_registry_server
    username = var.docker_registry_username
    password = var.docker_registry_password
  }

  template {
    container {
      name   = var.name
      image  = var.image
      cpu    = var.cpu
      memory = "${var.memory}Gi"

      env = [
        for k, v in var.environment_variables : {
          name  = k
          value = v
        }
      ]
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }
}

############################################
# Outputs
############################################
output "container_app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}
