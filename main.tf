
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    environment = "lab-02a"
  }
}

data "azuread_domains" "default" {
  only_initial = true
}

resource "azuread_user" "aaduser1" {
  user_principal_name = "aaduser1@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "aaduser1"
  mail_nickname       = "aaduser1"
  password            = "Pa55w.rd1234!"
}

resource "azuread_user" "aaduser2" {
  user_principal_name = "aaduser2@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "aaduser2"
  mail_nickname       = "aaduser2"
  password            = "Pa55w.rd1234!"
}

resource "azuread_user" "aaduser3" {
  user_principal_name = "aaduser3@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "aaduser3"
  mail_nickname       = "aaduser3"
  password            = "Pa55w.rd1234!"
}

resource "azuread_user" "aaduser4" {
  user_principal_name = "aaduser4@${data.azuread_domains.default.domains[0].domain_name}"
  display_name        = "aaduser4"
  mail_nickname       = "aaduser4"
  password            = "Pa55w.rd1234!"
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_definition" "vm_operator" {
  name        = "Azure Virtual Machine Operator"
  scope       = data.azurerm_subscription.primary.id
  description = "Custom role for AZ-104 Lab: Can start and restart virtual machines."

  permissions {
    actions = [
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read",
      "Microsoft.Network/virtualNetworks/read",
      "Microsoft.Network/virtualNetworks/subnets/read",
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/networkInterfaces/read",
      "Microsoft.Network/networkInterfaces/write",
      "Microsoft.Network/networkInterfaces/join/action",
      "Microsoft.Network/networkSecurityGroups/read",
      "Microsoft.Network/networkSecurityGroups/join/action",
      "Microsoft.Compute/virtualMachines/read",
      "Microsoft.Compute/virtualMachines/start/action",
      "Microsoft.Compute/virtualMachines/restart/action",
      "Microsoft.Compute/virtualMachines/deallocate/action",
      "Microsoft.Authorization/*/read"
    ]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.primary.id
  ]
}

resource "azurerm_virtual_network" "main" {
  name                = "az104-02a-vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "main" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "main" {
  name                = "az104-02a-nic1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "main" {
  name                = "az104-02a-vm1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.vm_admin_username
  admin_password      = var.vm_admin_password
  network_interface_ids = [
    azurerm_network_interface.main.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [azurerm_resource_group.main]
}

resource "azurerm_role_assignment" "aaduser1_vm_operator" {
  scope              = azurerm_resource_group.main.id
  role_definition_id = azurerm_role_definition.vm_operator.role_definition_resource_id
  principal_id       = azuread_user.aaduser1.object_id
}
