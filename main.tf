terraform {
  required_version = ">= 1.3"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# -----------------------------
# Resource Group
# -----------------------------
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg7"
  location = "polandcentral"
}

# -----------------------------
# Storage Account
# -----------------------------
resource "azurerm_storage_account" "sa" {
  name                     = "az104sa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
  public_network_access_enabled  = true

  blob_properties {
    delete_retention_policy {
      days = 7
    }
  }

  tags = {
    lab = "az104-lab07"
  }
}

# -----------------------------
# Blob Container (private)
# -----------------------------
resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

# -----------------------------
# Lifecycle Management (Move to Cool after 30 days)
# -----------------------------
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.sa.id

  rule {
    name    = "movetocool"
    enabled = true

    filters {
      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

# -----------------------------
# File Share
# -----------------------------
resource "azurerm_storage_share" "share1" {
  name                 = "share1"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 50
}

# -----------------------------
# Virtual Network + Service Endpoint
# -----------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]

  service_endpoints = ["Microsoft.Storage"]
}

# -----------------------------
# Storage Account Network Rules
# -----------------------------
resource "azurerm_storage_account_network_rules" "rules" {
  storage_account_id = azurerm_storage_account.sa.id

  default_action             = "Deny"
  virtual_network_subnet_ids = [azurerm_subnet.default.id]
}
