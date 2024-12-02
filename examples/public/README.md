<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the module in its simplest form.

```hcl
terraform {
  required_version = "~> 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.74"
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

locals {
  regions_with_zones = [
    for v in module.regions.regions : v if v.zones != null
  ]
}

## Section to provide a random Azure region for the resource group
# This allows us to randomize the region for the resource group.
module "regions" {
  source  = "Azure/regions/azurerm"
  version = "~> 0.3"
}

data "azurerm_client_config" "current" {}

# This allows us to randomize the region for the resource group.
resource "random_integer" "region_index" {
  max = length(local.regions_with_zones.length) - 1
  min = 0
}
## End of section to provide a random Azure region for the resource group

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = local.regions_with_zones[random_integer.region_index.result].name
  name     = module.naming.resource_group.name_unique
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
  location                  = azurerm_resource_group.this.location
  name                      = module.naming.key_vault.name_unique
  resource_group_name       = azurerm_resource_group.this.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true
}

resource "azurerm_role_assignment" "current" {
  principal_id         = data.azurerm_client_config.current.object_id
  scope                = azurerm_key_vault.keyvault.id
  role_definition_name = "Key Vault Administrator"
}

resource "azurerm_key_vault_secret" "secret" {
  key_vault_id    = azurerm_key_vault.keyvault.id
  name            = "secretname"
  value           = "password123"
  expiration_date = "2024-12-30T20:00:00Z"

  depends_on = [azurerm_role_assignment.current]
}



module "test" {
  source              = "../../"
  location            = azurerm_resource_group.this.location
  name                = module.naming.container_group.name_unique
  resource_group_name = azurerm_resource_group.this.name
  os_type             = "Linux"
  restart_policy      = "Always"
  diagnostics_log_analytics = {
    workspace_id  = azurerm_log_analytics_workspace.this.workspace_id
    workspace_key = azurerm_log_analytics_workspace.this.primary_shared_key
  }
  tags = {
    clustertype = "public"
  }
  zones            = ["1"]
  priority         = "Regular"
  enable_telemetry = var.enable_telemetry
  containers = {
    container1 = {
      name   = "container1"
      image  = "nginx:latest"
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
  role_assignments = {
    role_assignment_1 = {
      role_definition_id_or_name       = "Contributor"
      principal_id                     = data.azurerm_client_config.current.object_id
      skip_service_principal_aad_check = false
    }
  }
}
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.74)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.74)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.keyvault](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_secret.secret](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_log_analytics_workspace.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) (resource)
- [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_role_assignment.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [azurerm_user_assigned_identity.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) (resource)
- [random_integer.region_index](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/integer) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: ~> 0.3

### <a name="module_regions"></a> [regions](#module\_regions)

Source: Azure/regions/azurerm

Version: ~> 0.3

### <a name="module_test"></a> [test](#module\_test)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->