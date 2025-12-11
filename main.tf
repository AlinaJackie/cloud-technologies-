terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg5"
  location = "polandcentral"
}

resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "core_subnet" {
  name                 = "Core"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "core_nic" {
  name                = "CoreServicesVM-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.core_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "core_vm" {
  name                  = "CoreServicesVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "localadmin"
  admin_password        = "ComplexPassword123!"
  network_interface_ids = [azurerm_network_interface.core_nic.id]

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

  provision_vm_agent = true
  boot_diagnostics {}
}

resource "azurerm_virtual_network" "manufacturing_vnet" {
  name                = "ManufacturingVnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["172.16.0.0/16"]
}

resource "azurerm_subnet" "manufacturing_subnet" {
  name                 = "Manufacturing"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.manufacturing_vnet.name
  address_prefixes     = ["172.16.0.0/24"]
}

resource "azurerm_network_interface" "manufacturing_nic" {
  name                = "ManufacturingVM-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.manufacturing_subnet.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_windows_virtual_machine" "manufacturing_vm" {
  name                  = "ManufacturingVM"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = "localadmin"
  admin_password        = "ComplexPassword123!"
  network_interface_ids = [azurerm_network_interface.manufacturing_nic.id]

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

  provision_vm_agent = true
  boot_diagnostics {}
}

resource "azurerm_virtual_network_peering" "core_to_manufacturing" {
  name                         = "CoreServicesVnet-to-ManufacturingVnet"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.core_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.manufacturing_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_virtual_network_peering" "manufacturing_to_core" {
  name                         = "ManufacturingVnet-to-CoreServicesVnet"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.manufacturing_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.core_vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
}

resource "azurerm_subnet" "perimeter_subnet" {
  name                 = "perimeter"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_route_table" "rt_coreservices" {
  name                = "rt-CoreServices"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  bgp_route_propagation_enabled = false
}

resource "azurerm_route" "perimeterto_core" {
  name                = "PerimetertoCore"
  resource_group_name = azurerm_resource_group.rg.name
  route_table_name    = azurerm_route_table.rt_coreservices.name
  address_prefix      = "10.0.0.0/16"
  next_hop_type       = "VirtualAppliance"
  next_hop_in_ip_address = "10.0.1.7"
}

resource "azurerm_subnet_route_table_association" "core_subnet_association" {
  subnet_id      = azurerm_subnet.core_subnet.id
  route_table_id = azurerm_route_table.rt_coreservices.id
}