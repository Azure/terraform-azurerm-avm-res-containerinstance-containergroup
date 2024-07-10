output "fqdn" {
  description = "The FQDN of the container group derived from `dns_name_label"
  value       = one(azurerm_container_group.this[*].fqdn)
}

output "ip_address" {
  description = "The IP address allocated to the container group"
  value       = one(azurerm_container_group.this[*].ip_address)
}

output "name" {
  description = "Name of the container group"
  value       = one(azurerm_container_group.this[*].name)
}

output "resource_group_name" {
  description = "Name of the container group resource group"
  value       = one(azurerm_container_group.this[*].resource_group_name)
}

output "resource_id" {
  description = "Resource ID of Container Group Instance"
  value       = one(azurerm_container_group.this[*].id)
}
