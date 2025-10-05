
output "detected_tenant_domain" {
  description = "The automatically detected tenant domain"
  value       = data.azuread_domains.default.domains[0].domain_name
}

output "resource_group_name" {
  description = "The name of the created resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "The location of the created resource group"
  value       = azurerm_resource_group.main.location
}

output "virtual_machine_name" {
  description = "The name of the created virtual machine"
  value       = azurerm_windows_virtual_machine.main.name
}

output "virtual_machine_id" {
  description = "The ID of the created virtual machine"
  value       = azurerm_windows_virtual_machine.main.id
}

output "vm_operator_role_name" {
  description = "The name of the custom RBAC role"
  value       = azurerm_role_definition.vm_operator.name
}

output "vm_operator_role_id" {
  description = "The ID of the custom RBAC role"
  value       = azurerm_role_definition.vm_operator.role_definition_resource_id
}

output "created_users" {
  description = "List of created Azure AD users"
  value = [
    for u in [azuread_user.aaduser1, azuread_user.aaduser2, azuread_user.aaduser3, azuread_user.aaduser4] : {
      name      = u.display_name
      upn       = u.user_principal_name
      object_id = u.object_id
    }
  ]
}

output "role_assignment_info" {
  description = "Information about the role assignment"
  value = {
    user          = azuread_user.aaduser1.user_principal_name
    role          = azurerm_role_definition.vm_operator.name
    scope         = azurerm_resource_group.main.name
    assignment_id = azurerm_role_assignment.aaduser1_vm_operator.id
  }
}

output "network_info" {
  description = "Network configuration information"
  value = {
    vnet_name      = azurerm_virtual_network.main.name
    vnet_address   = azurerm_virtual_network.main.address_space[0]
    subnet_name    = azurerm_subnet.main.name
    subnet_address = azurerm_subnet.main.address_prefixes[0]
    nic_name       = azurerm_network_interface.main.name
  }
}

output "vm_connection_info" {
  description = "Information for connecting to the VM"
  value = {
    admin_username = azurerm_windows_virtual_machine.main.admin_username
    computer_name  = azurerm_windows_virtual_machine.main.computer_name
  }
  sensitive = true
}
