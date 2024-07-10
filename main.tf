resource "azurerm_container_group" "this" {
  location                            = var.location
  name                                = var.name
  os_type                             = var.os_type
  resource_group_name                 = var.resource_group_name
  dns_name_label                      = length(var.subnet_ids) == 0 ? var.dns_name_label : null
  dns_name_label_reuse_policy         = var.dns_name_label_reuse_policy
  ip_address_type                     = length(var.subnet_ids) == 0 ? "Public" : "Private"
  key_vault_key_id                    = var.key_vault_key_id
  key_vault_user_assigned_identity_id = var.key_vault_user_assigned_identity_id
  priority                            = var.priority
  restart_policy                      = var.restart_policy
  subnet_ids                          = length(var.subnet_ids) == 0 ? null : var.subnet_ids
  tags                                = var.tags
  zones                               = var.zones

  dynamic "container" {
    for_each = var.containers
    content {
      cpu                   = container.value.cpu
      image                 = container.value.image
      memory                = container.value.memory
      name                  = container.key
      commands              = try(container.value.commands, null)
      environment_variables = try(container.value.environment_variables, null)
      # secure_environment_variables = try(var.container_secure_environment_variables[container.key].value, null) 
      secure_environment_variables = try(container.value.secure_environment_variables, null)

      dynamic "liveness_probe" {
        for_each = try(var.liveness_probe, null) == null ? [] : [1]

        content {
          exec                  = try(liveness_probe.value.exec, null)
          failure_threshold     = try(liveness_probe.value.failure_threshold, 3)
          initial_delay_seconds = try(liveness_probe.value.initial_delay_seconds, null)
          period_seconds        = try(liveness_probe.value.period_seconds, 10)
          success_threshold     = try(liveness_probe.value.success_threshold, 1)
          timeout_seconds       = try(liveness_probe.value.timeout_seconds, 1)

          dynamic "http_get" {
            for_each = try(liveness_probe.value.http_get, {}) == {} ? [] : [1]

            content {
              path   = try(http_get.value.path, null)
              port   = try(http_get.value.port, null)
              scheme = try(http_get.value.scheme, null)
            }
          }
        }
      }
      dynamic "ports" {
        for_each = container.value.ports
        content {
          port     = ports.value.port
          protocol = try(upper(ports.value.protocol), "TCP")
        }
      }
      dynamic "readiness_probe" {
        for_each = try(var.readiness_probe, null) == null ? [] : [1]

        content {
          exec                  = try(readiness_probe.value.exec, null)
          failure_threshold     = try(readiness_probe.value.failure_threshold, 3)
          initial_delay_seconds = try(readiness_probe.value.initial_delay_seconds, null)
          period_seconds        = try(readiness_probe.value.period_seconds, 10)
          success_threshold     = try(readiness_probe.value.success_threshold, 1)
          timeout_seconds       = try(readiness_probe.value.timeout_seconds, 1)

          dynamic "http_get" {
            for_each = try(readiness_probe.value.http_get, {}) == {} ? [] : [1]

            content {
              path   = try(http_get.value.path, null)
              port   = try(http_get.value.port, null)
              scheme = try(http_get.value.scheme, null)
            }
          }
        }
      }
      dynamic "volume" {
        for_each = container.value.volumes
        content {
          mount_path = volume.value.mount_path
          name       = volume.key
          empty_dir  = try(volume.value.empty_dir, false)
          read_only  = try(volume.value.read_only, false)
          # secret               = try(var.container_volume_secrets[container.key].volume[volume.key], null)
          secret               = try(volume.value.secret, null)
          share_name           = try(volume.value.share_name, null)
          storage_account_key  = try(volume.value.storage_account_key, null)
          storage_account_name = try(volume.value.storage_account_name, null)

          dynamic "git_repo" {
            for_each = volume.value.git_repo != null ? [volume.value.git_repo] : []
            content {
              url       = git_repo.value.url
              directory = git_repo.value.directory
              revision  = git_repo.value.revision
            }
          }
        }
      }
    }
  }
  dynamic "diagnostics" {
    for_each = var.diagnostics_log_analytics != null ? [var.diagnostics_log_analytics] : []
    content {
      log_analytics {
        workspace_id  = diagnostics.value.workspace_id
        workspace_key = diagnostics.value.workspace_key
      }
    }
  }
  dynamic "dns_config" {
    for_each = toset(length(var.dns_name_servers) > 0 ? [var.dns_name_servers] : [])
    content {
      nameservers    = dns_config.value
      options        = try(dns_config.options, null)
      search_domains = try(dns_config.search_domains, null)
    }
  }
  dynamic "exposed_port" {
    for_each = var.exposed_ports
    content {
      port     = exposed_port.value.port
      protocol = upper(exposed_port.value.protocol)
    }
  }
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned
    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "image_registry_credential" {
    for_each = var.image_registry_credential
    content {
      server                    = image_registry_credential.value.server
      password                  = image_registry_credential.value.password
      user_assigned_identity_id = image_registry_credential.value.user_assigned_identity_id
      username                  = image_registry_credential.value.username
    }
  }
  timeouts {
    create = "2h"
    update = "2h"
  }
}

resource "azurerm_role_assignment" "this" {
  for_each = var.role_assignments

  principal_id                           = each.value.principal_id
  scope                                  = azurerm_container_group.this.id
  condition                              = each.value.condition
  condition_version                      = each.value.condition_version
  delegated_managed_identity_resource_id = each.value.delegated_managed_identity_resource_id
  role_definition_id                     = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? each.value.role_definition_id_or_name : null
  role_definition_name                   = strcontains(lower(each.value.role_definition_id_or_name), lower(local.role_definition_resource_substring)) ? null : each.value.role_definition_id_or_name
  skip_service_principal_aad_check       = each.value.skip_service_principal_aad_check
}


