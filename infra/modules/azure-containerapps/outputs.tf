
output "container_app_url" {
  value = azurerm_container_app.app.latest_revision_fqdn
}

output "subnet_id" {
  value = azurerm_subnet.subnet.id
}