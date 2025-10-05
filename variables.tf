variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "az104-02a-rg1"
}

variable "location" {
  description = "The Azure location where resources will be created"
  type        = string
  default     = "polandcentral" 
}

variable "subscription_id" {
  description = "The subscription ID where resources will be created"
  type        = string
  default     = "3d0f5294-8c4b-4a22-8b26-85a177e7cd10"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "vm_admin_username" {
  description = "Admin username for the virtual machine"
  type        = string
  default     = "azureuser"
}

variable "vm_admin_password" {
  description = "Admin password for the virtual machine"
  type        = string
  default     = "Pa55w.rd1234!"
  sensitive   = true
}
