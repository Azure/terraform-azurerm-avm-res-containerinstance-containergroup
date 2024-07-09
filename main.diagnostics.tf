
# Enable Diagnostic Settings for Container Group
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  for_each = var.diagnostic_settings == null ? {} : var.diagnostic_settings

  name                           = each.value.name
  target_resource_id             = azurerm_container_group.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_workspace_id     = each.value.workspace_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
    }
  }
}
