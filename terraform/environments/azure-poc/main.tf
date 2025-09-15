resource "azurerm_postgresql_flexible_server" "poc" {
  name                   = "lakerunner-poc-postgres"
  resource_group_name    = azurerm_resource_group.poc.name
  location               = azurerm_resource_group.poc.location
  administrator_login    = "lakerunneradmin"
  administrator_password = "LakerunnerPoc2025!"
  sku_name               = "B_Standard_B1ms"
  storage_mb             = 32768
  version                = "13"
  backup_retention_days  = 7
  geo_redundant_backup_enabled = false
  zone                   = "1"
  public_network_access_enabled = true
}
resource "azurerm_resource_group" "poc" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "poc" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.poc.name
  location                 = azurerm_resource_group.poc.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_network" "poc" {
  name                = var.vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.poc.location
  resource_group_name = azurerm_resource_group.poc.name
}

resource "azurerm_subnet" "poc" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.poc.name
  virtual_network_name = azurerm_virtual_network.poc.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "poc" {
  name                = var.nic_name
  location            = azurerm_resource_group.poc.location
  resource_group_name = azurerm_resource_group.poc.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.poc.id
    private_ip_address_allocation = "Dynamic"
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
}
resource "azurerm_linux_virtual_machine" "poc" {
  name                = var.vm_name
  resource_group_name = azurerm_resource_group.poc.name
  location            = azurerm_resource_group.poc.location
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [azurerm_network_interface.poc.id]
  disable_password_authentication = true
  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
