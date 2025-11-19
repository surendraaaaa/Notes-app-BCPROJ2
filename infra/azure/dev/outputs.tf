############################################
# Outputs
############################################
output "frontend_app_url" {
  value = module.frontend.container_app_url
}

output "backend_app_url" {
  value = module.backend.container_app_url
}

output "mysql_fqdn" {
  value = azurerm_mysql_flexible_server.notes.fqdn
}

output "frontend_subnet_id" {
  value = module.frontend.subnet_id
}

output "backend_subnet_id" {
  value = module.backend.subnet_id
}