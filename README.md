<!-- BEGIN_TF_DOCS -->
# terraform-azurerm-avm-template

This is a template repo for Terraform Azure Verified Modules.

Things to do:

1. Set up a GitHub repo environment called `test`.
1. Configure environment protection rule to ensure that approval is required before deploying to this environment.
1. Create a user-assigned managed identity in your test subscription.
1. Create a role assignment for the managed identity on your test subscription, use the minimum required role.
1. Configure federated identity credentials on the user assigned managed identity. Use the GitHub environment.
1. Search and update TODOs within the code and remove the TODO comments once complete.

> [!IMPORTANT]
> As the overall AVM framework is not GA (generally available) yet - the CI framework and test automation is not fully functional and implemented across all supported languages yet - breaking changes are expected, and additional customer feedback is yet to be gathered and incorporated. Hence, modules **MUST NOT** be published at version `1.0.0` or higher at this time.
>
> All module **MUST** be published as a pre-release version (e.g., `0.1.0`, `0.1.1`, `0.2.0`, etc.) until the AVM framework becomes GA.
>
> However, it is important to note that this **DOES NOT** mean that the modules cannot be consumed and utilized. They **CAN** be leveraged in all types of environments (dev, test, prod etc.). Consumers can treat them just like any other IaC module and raise issues or feature requests against them as they learn from the usage of the module. Consumers should also read the release notes for each version, if considering updating to a more recent version of a module to see if there are any considerations or breaking changes etc.

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.5)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (~> 3.71)

- <a name="requirement_random"></a> [random](#requirement\_random) (~> 3.5)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (~> 3.71)

- <a name="provider_random"></a> [random](#provider\_random) (~> 3.5)

## Resources

The following resources are used by this module:

- [azurerm_container_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_group) (resource)
- [azurerm_monitor_diagnostic_setting.container_group](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/monitor_diagnostic_setting) (resource)
- [azurerm_private_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint) (resource)
- [azurerm_private_endpoint_application_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint_application_security_group_association) (resource)
- [azurerm_resource_group_template_deployment.telemetry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group_template_deployment) (resource)
- [azurerm_role_assignment.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) (resource)
- [random_id.telem](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

The following input variables are required:

### <a name="input_location"></a> [location](#input\_location)

Description: Azure region where the resource should be deployed.

Type: `string`

### <a name="input_name"></a> [name](#input\_name)

Description: The name of the resource.

Type: `string`

### <a name="input_os_type"></a> [os\_type](#input\_os\_type)

Description: The operating system type for the container group.

Type: `string`

### <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name)

Description: The name of the resource group in which to create the resource.

Type: `string`

### <a name="input_restart_policy"></a> [restart\_policy](#input\_restart\_policy)

Description: The restart policy for the container group.

Type: `string`

### <a name="input_tags"></a> [tags](#input\_tags)

Description: (Optional) Tags of the resource.

Type: `map(string)`

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_containers"></a> [containers](#input\_containers)

Description: A map of containers to run in the container group.

Type:

```hcl
map(object({
    image  = string
    cpu    = number
    memory = number
    ports = list(object({
      port     = number
      protocol = string
    }))
    volumes = map(object({
      mount_path           = string
      name                 = string
      read_only            = optional(bool, false)
      empty_dir            = optional(bool, false)
      secret               = optional(map(string), null)
      storage_account_name = optional(string, null)
      storage_account_key  = optional(string, null)
      share_name           = optional(string, null)
      git_repo = optional(object({
        url       = optional(string, null)
        directory = optional(string, null)
        revision  = optional(string, null)
      }))
    }))
    environment_variables        = optional(map(string), {})
    secure_environment_variables = optional(map(string), {})
    commands                     = optional(list(string), null)
  }))
```

Default: `{}`

### <a name="input_diagnostic_settings"></a> [diagnostic\_settings](#input\_diagnostic\_settings)

Description: A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.

Type:

```hcl
map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
    metadata                                 = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_diagnostics_log_analytics"></a> [diagnostics\_log\_analytics](#input\_diagnostics\_log\_analytics)

Description: The Log Analytics workspace configuration for diagnostics.

Type:

```hcl
object({
    workspace_id  = string
    workspace_key = string
  })
```

Default: `null`

### <a name="input_dns_name_label"></a> [dns\_name\_label](#input\_dns\_name\_label)

Description: The DNS name label for the container group.

Type: `string`

Default: `null`

### <a name="input_dns_name_label_reuse_policy"></a> [dns\_name\_label\_reuse\_policy](#input\_dns\_name\_label\_reuse\_policy)

Description: The DNS name label reuse policy for the container group.

Type: `string`

Default: `null`

### <a name="input_dns_name_servers"></a> [dns\_name\_servers](#input\_dns\_name\_servers)

Description: A list of DNS name servers to use for the container group.

Type: `list(string)`

Default: `[]`

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

### <a name="input_exposed_ports"></a> [exposed\_ports](#input\_exposed\_ports)

Description: A list of ports to expose on the container group.

Type:

```hcl
list(object({
    port     = number
    protocol = string
  }))
```

Default: `[]`

### <a name="input_image_registry_credential"></a> [image\_registry\_credential](#input\_image\_registry\_credential)

Description: The credentials for the image registry.

Type:

```hcl
map(object({
    user_assigned_identity_id = string
    server                    = string
    username                  = string
    password                  = string
  }))
```

Default: `{}`

### <a name="input_key_vault_key_id"></a> [key\_vault\_key\_id](#input\_key\_vault\_key\_id)

Description: The Key Vault key ID for the container group.

Type: `string`

Default: `null`

### <a name="input_key_vault_user_assigned_identity_id"></a> [key\_vault\_user\_assigned\_identity\_id](#input\_key\_vault\_user\_assigned\_identity\_id)

Description: The Key Vault user-assigned identity ID for the container group.

Type: `string`

Default: `null`

### <a name="input_liveness_probe"></a> [liveness\_probe](#input\_liveness\_probe)

Description: The liveness probe configuration for the container group.

Type:

```hcl
object({
    exec = object({
      command = list(string)
    })
    period_seconds        = number
    failure_threshold     = number
    success_threshold     = number
    timeout_seconds       = number
    initial_delay_seconds = number
    http_get = object({
      path         = string
      port         = number
      http_headers = map(string)
    })
    tcp_socket = object({
      port = number
    })
  })
```

Default: `null`

### <a name="input_managed_identities"></a> [managed\_identities](#input\_managed\_identities)

Description:   Controls the Managed Identity configuration on this resource. The following properties can be specified:

  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Type:

```hcl
object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
```

Default: `{}`

### <a name="input_priority"></a> [priority](#input\_priority)

Description: The Priority for the container group.

Type: `string`

Default: `null`

### <a name="input_private_endpoints"></a> [private\_endpoints](#input\_private\_endpoints)

Description: Private Endpoints Configuration

Type:

```hcl
map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    subresource_name                        = string # NOTE: `subresource_name` can be excluded if the resource does not support multiple sub resource types (e.g. storage account supports blob, queue, etc)
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
```

Default: `{}`

### <a name="input_readiness_probe"></a> [readiness\_probe](#input\_readiness\_probe)

Description: The readiness probe configuration for the container group.

Type:

```hcl
object({
    exec = object({
      command = list(string)
    })
    period_seconds        = number
    failure_threshold     = number
    success_threshold     = number
    timeout_seconds       = number
    initial_delay_seconds = number
    http_get = object({
      path         = string
      port         = number
      http_headers = map(string)
    })
    tcp_socket = object({
      port = number
    })
  })
```

Default: `null`

### <a name="input_role_assignments"></a> [role\_assignments](#input\_role\_assignments)

Description: The role assignments for the container group.

Type:

```hcl
map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
```

Default: `{}`

### <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids)

Description: The subnet IDs for the container group.

Type: `list(string)`

Default: `[]`

### <a name="input_zones"></a> [zones](#input\_zones)

Description: A list of availability zones in which the resource should be created.

Type: `list(string)`

Default: `[]`

## Outputs

The following outputs are exported:

### <a name="output_fqdn"></a> [fqdn](#output\_fqdn)

Description: The FQDN of the container group derived from `dns_name_label`

### <a name="output_ip_address"></a> [ip\_address](#output\_ip\_address)

Description: The IP address allocated to the container group

### <a name="output_name"></a> [name](#output\_name)

Description: Name of the container group

### <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name)

Description: Name of the container group resource group

### <a name="output_resource_id"></a> [resource\_id](#output\_resource\_id)

Description: Resource ID of Container Group Instance

## Modules

No modules.

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->