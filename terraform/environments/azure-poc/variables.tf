variable "ssh_public_key" {
  description = "SSH public key for VM admin access (use the contents of your id_rsa.pub or similar)"
  type        = string
}
variable "subscription_id" {
  description = "Azure Subscription ID for authentication"
  type        = string
}

variable "client_id" {
  description = "Azure Client ID for Service Principal authentication"
  type        = string
}

variable "client_secret" {
  description = "Azure Client Secret for Service Principal authentication"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID for authentication"
  type        = string
}
variable "resource_group_name" {
  description = "Name of the resource group for the POC deployment"
  type        = string
  default     = "lakerunner-poc-rg"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Main application storage account name"
  type        = string
  default     = "lakerunnerpocstorage"
}

variable "vnet_name" {
  description = "Virtual network name for the POC environment"
  type        = string
  default     = "lakerunner-poc-vnet"
}

variable "subnet_name" {
  description = "Subnet name for the POC environment"
  type        = string
  default     = "lakerunner-poc-subnet"
}

variable "nic_name" {
  description = "Network interface name for the VM"
  type        = string
  default     = "lakerunner-poc-nic"
}

variable "vm_name" {
  description = "Virtual machine name for the POC deployment"
  type        = string
  default     = "lakerunner-poc-vm"
}

variable "vm_size" {
  description = "Size of the virtual machine (default: cost-effective for POC, use Standard_B1s for broad availability)"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM (do not use 'admin' for security)"
  type        = string
  default     = "lakerunner"
}

variable "admin_password" {
  description = "Admin password for the VM (change before production use)"
  type        = string
  sensitive   = true
  default     = "LakerunnerPoc2025!"
}
