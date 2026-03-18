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
      image  = "nginx:latest"
      cpu    = "1"
      memory = "1.5"
      ports = [
        {
          port     = 80
          protocol = "TCP"
        }
      ]
    }
  }
  enable_telemetry = var.enable_telemetry
  exposed_ports = [
    {
      port     = 80
      protocol = "TCP"
    }
  ]
  tags = {
    purpose = "no-volumes-example"
  }
}
