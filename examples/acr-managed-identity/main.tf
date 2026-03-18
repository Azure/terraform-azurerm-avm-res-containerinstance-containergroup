terraform {
  required_version = "~> 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "0.3.1"
}

data "azurerm_client_config" "current" {}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# Create a user-assigned managed identity for ACI
resource "azurerm_user_assigned_identity" "aci" {
  location            = azurerm_resource_group.this.location
  name                = "${module.naming.user_assigned_identity.name_unique}-aci"
  resource_group_name = azurerm_resource_group.this.name
}

# Create Azure Container Registry
resource "azurerm_container_registry" "this" {
  location            = azurerm_resource_group.this.location
  name                = replace(module.naming.container_registry.name_unique, "-", "")
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Basic"
  admin_enabled       = false
}

# Grant AcrPull role to the managed identity
resource "azurerm_role_assignment" "acr_pull" {
  principal_id         = azurerm_user_assigned_identity.aci.principal_id
  scope                = azurerm_container_registry.this.id
  role_definition_name = "AcrPull"
}

# Deploy container group with ACR access using managed identity
module "test" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.container_group.name_unique
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.this.name
  restart_policy      = "Always"

  containers = {
    nginx = {
      name   = "nginx"
      image  = "${azurerm_container_registry.this.login_server}/nginx:latest"
      cpu    = "0.5"
      memory = "1.5"
      ports = [
        {
          port     = 80
          protocol = "TCP"
        }
      ]
      volumes = {}
    }
  }

  enable_telemetry = var.enable_telemetry

  exposed_ports = [
    {
      port     = 80
      protocol = "TCP"
    }
  ]

  # Use managed identity for ACR authentication
  managed_identities = {
    user_assigned_resource_ids = [azurerm_user_assigned_identity.aci.id]
  }

  # Configure image registry credential with managed identity (no username/password required)
  image_registry_credential = {
    acr = {
      server                    = azurerm_container_registry.this.login_server
      user_assigned_identity_id = azurerm_user_assigned_identity.aci.id
    }
  }

  tags = {
    environment = "test"
    example     = "acr-managed-identity"
  }

  depends_on = [azurerm_role_assignment.acr_pull]
}
