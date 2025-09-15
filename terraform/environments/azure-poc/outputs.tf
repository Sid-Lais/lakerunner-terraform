output "postgresql_connection_string" {
  value = "postgresql://lakerunneradmin:LakerunnerPoc2025!@${azurerm_postgresql_flexible_server.poc.fqdn}:5432/postgres?sslmode=require"
}
output "resource_group_name" {
  value = azurerm_resource_group.poc.name
}

output "storage_account_name" {
  value = azurerm_storage_account.poc.name
}

output "vm_public_ip" {
  value = azurerm_linux_virtual_machine.poc.public_ip_address
}
