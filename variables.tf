variable "location" {
  type        = string
  description = "Azure region where the resource should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the resource."
  nullable    = false
}

variable "os_type" {
  type        = string
  description = "The operating system type for the container group."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the resource."
  nullable    = false
}

variable "restart_policy" {
  type        = string
  description = "The restart policy for the container group."
}


variable "tags" {
  type        = map(string)
  description = "(Optional) Tags of the resource."
  default  = null
}

variable "containers" {
  type = map(object({
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
  default     = {}
  description = "A map of containers to run in the container group."
}

# variable "diagnostic_settings" {
#   type = map(object({
#     name                                     = optional(string, null)
#     log_categories                           = optional(set(string), [])
#     log_groups                               = optional(set(string), ["allLogs"])
#     metric_categories                        = optional(set(string), ["AllMetrics"])
#     log_analytics_destination_type           = optional(string, "Dedicated")
#     workspace_resource_id                    = optional(string, null)
#     storage_account_resource_id              = optional(string, null)
#     event_hub_authorization_rule_resource_id = optional(string, null)
#     event_hub_name                           = optional(string, null)
#     marketplace_partner_resource_id          = optional(string, null)
#   }))
#   default     = {}
#   description = <<DESCRIPTION
# A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

# - `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
# - `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
# - `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
# - `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
# - `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
# - `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
# - `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
# - `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
# - `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
# - `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
# DESCRIPTION  
#   nullable    = false

#   validation {
#     condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
#     error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
#   }
#   validation {
#     condition = alltrue(
#       [
#         for _, v in var.diagnostic_settings :
#         v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
#       ]
#     )
#     error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
#   }
# }

variable "diagnostics_log_analytics" {
  type = object({
    workspace_id  = string
    workspace_key = string
  })
  default     = null
  description = "The Log Analytics workspace configuration for diagnostics."
}

variable "dns_name_label" {
  type        = string
  default     = null
  description = "The DNS name label for the container group."
}

variable "dns_name_label_reuse_policy" {
  type        = string
  default     = null
  description = "The DNS name label reuse policy for the container group."
}

variable "dns_name_servers" {
  type        = list(string)
  default     = []
  description = "A list of DNS name servers to use for the container group."
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "exposed_ports" {
  type = list(object({
    port     = number
    protocol = string
  }))
  default     = []
  description = "A list of ports to expose on the container group."
}

variable "image_registry_credential" {
  type = map(object({
    user_assigned_identity_id = string
    server                    = string
    username                  = string
    password                  = string
  }))
  default     = {}
  description = "The credentials for the image registry."
}

variable "key_vault_key_id" {
  type        = string
  default     = null
  description = "The Key Vault key ID for the container group."
}

variable "key_vault_user_assigned_identity_id" {
  type        = string
  default     = null
  description = "The Key Vault user-assigned identity ID for the container group."
}

variable "liveness_probe" {
  type = object({
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
  default     = null
  description = "The liveness probe configuration for the container group."
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
  Controls the Managed Identity configuration on this resource. The following properties can be specified:
  
  - `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
  - `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.
  DESCRIPTION
  nullable    = false
}

variable "priority" {
  type        = string
  default     = null
  description = "The Priority for the container group."
}

variable "private_endpoints" {
  type = map(object({
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
  default     = {}
  description = "Private Endpoints Configuration"
  nullable    = false
}

variable "readiness_probe" {
  type = object({
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
  default     = null
  description = "The readiness probe configuration for the container group."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = "The role assignments for the container group."
  nullable    = false
}

variable "subnet_ids" {
  type        = list(string)
  default     = []
  description = "The subnet IDs for the container group."
}

variable "zones" {
  type        = list(string)
  default     = []
  description = "A list of availability zones in which the resource should be created."
}
