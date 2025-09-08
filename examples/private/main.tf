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
  features {}
}


## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.7.0"

  has_availability_zones = true
  recommended_filter     = false
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
  version = "0.4.2"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = module.regions.regions[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
}

# A vnet is required for the private endpoint.
resource "azurerm_virtual_network" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.virtual_network.name_unique
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["192.168.0.0/24"]
}

resource "azurerm_subnet" "this" {
  address_prefixes     = ["192.168.0.0/24"]
  name                 = module.naming.subnet.name_unique
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name

  delegation {
    name = "delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}


resource "azurerm_log_analytics_workspace" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.log_analytics_workspace.name_unique
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
}

resource "azurerm_user_assigned_identity" "this" {
  location            = azurerm_resource_group.this.location
  name                = module.naming.user_assigned_identity.name_unique
  resource_group_name = azurerm_resource_group.this.name
}


resource "azurerm_key_vault" "keyvault" {
  location                   = azurerm_resource_group.this.location
  name                       = module.naming.key_vault.name_unique
  resource_group_name        = azurerm_resource_group.this.name
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  rbac_authorization_enabled = true
}

resource "azurerm_role_assignment" "current" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
}

resource "azurerm_key_vault_secret" "secret" {
  key_vault_id    = azurerm_key_vault.keyvault.id
  name            = "secretname"
  expiration_date = "2024-12-30T20:00:00Z"
  value           = "password123"

  depends_on = [azurerm_role_assignment.current]
}

module "test" {
  source = "../../"

  location            = azurerm_resource_group.this.location
  name                = module.naming.container_group.name_unique
  os_type             = "Linux"
  resource_group_name = azurerm_resource_group.this.name
  restart_policy      = "Always"
  containers = {
    container1 = {
      name   = "container1"
      image  = "ghcr.io/servercontainers/nginx:latest"
      cpu    = "1"
      memory = "2"
      ports = [
        {
          port     = 80
          protocol = "TCP"
        }
      ]
      environment_variables = {
        "ENVIRONMENT" = "production"
      }
      secure_environment_variables = {
        "SECENV" = "avmpoc"
      }
      volumes = {
        secrets = {
          mount_path = "/etc/secrets"
          name       = "secret1"
          secret = {
            "password" = base64encode("password123")
          }
        },
        nginx = {
          mount_path = "/usr/share/nginx/html"
          name       = "nginx"
          secret = {
            "indexpage" = base64encode("Hello, World!")
          }
        }
      }
    }
  }
  diagnostics_log_analytics = {
    workspace_id  = azurerm_log_analytics_workspace.this.workspace_id
    workspace_key = azurerm_log_analytics_workspace.this.primary_shared_key
  }
  enable_telemetry = var.enable_telemetry
  exposed_ports = [
    {
      port     = 80
      protocol = "TCP"
    }
  ]
  managed_identities = {
    system_assigned            = true
    user_assigned_resource_ids = [azurerm_user_assigned_identity.this.id]
  }
  priority = "Regular"
  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = "Contributor"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    }
  }
  subnet_ids = [azurerm_subnet.this.id]
  tags = {
    cc = "avm"
  }
  zones = ["1"]
}
