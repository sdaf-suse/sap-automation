# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.


#######################################4#######################################8
#                                                                              #
#                           Azure Key Vault endpoints                          #
#                                                                              #
#######################################4#######################################8


resource "azurerm_private_endpoint" "kv_user" {
  provider                             = azurerm.main
  count                                = var.deployer.use && var.use_private_endpoint ? 1 : 0
  name                                 = format("%s%s%s",
                                          var.naming.resource_prefixes.keyvault_private_link,
                                          local.prefix,
                                          var.naming.resource_suffixes.keyvault_private_link
                                        )
  resource_group_name                  = var.deployer_tfstate.created_resource_group_name
  location                             = var.deployer_tfstate.created_resource_group_location
  subnet_id                            = var.deployer_tfstate.subnet_mgmt_id
  custom_network_interface_name        = format("%s%s%s%s",
                                           var.naming.resource_prefixes.keyvault_private_link,
                                           local.prefix,
                                           var.naming.resource_suffixes.keyvault_private_link,
                                           var.naming.resource_suffixes.nic
                                         )

  private_service_connection {
                               name                           = format("%s%s%s",
                                                                  var.naming.resource_prefixes.keyvault_private_svc,
                                                                  local.prefix,
                                                                  var.naming.resource_suffixes.keyvault_private_svc
                                                                )
                               is_manual_connection           = false
                               private_connection_resource_id = var.deployer_tfstate.deployer_kv_user_arm_id
                               subresource_names              = [
                                                                  "Vault"
                                                                ]
                             }

  dynamic "private_dns_zone_group" {
                                     for_each = range(var.dns_settings.register_storage_accounts_keyvaults_with_dns ? 1 : 0)
                                     content {
                                               name                 = var.dns_settings.dns_zone_names.vault_dns_zone_name
                                               private_dns_zone_ids = [local.use_local_privatelink_dns ? azurerm_private_dns_zone.vault[0].id : data.azurerm_private_dns_zone.vault[0].id]
                                             }
                                   }

}
