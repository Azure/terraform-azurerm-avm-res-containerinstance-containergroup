# ACI supports private networking through VNet injection, not Private Link endpoints.
rule "avm_interface_private_endpoints" {
  enabled = false
}
