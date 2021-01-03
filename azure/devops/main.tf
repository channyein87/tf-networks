resource "azurerm_resource_group" "devops_rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

module "network" {
  source              = "Azure/network/azurerm"
  resource_group_name = azurerm_resource_group.devops_rg.name
  vnet_name           = "${var.prefix}-vnet"
  address_space       = var.vnet-cidr
  subnet_prefixes     = var.subnet-cidr
  subnet_names        = var.subnet-name

  depends_on = [azurerm_resource_group.devops_rg]
}

resource "azurerm_storage_account" "devops_stor" {
  name                     = "chkoazdevops"
  resource_group_name      = azurerm_resource_group.devops_rg.name
  location                 = azurerm_resource_group.devops_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_key_vault" "devops_kv" {
  name                       = "${var.prefix}-kv"
  resource_group_name        = azurerm_resource_group.devops_rg.name
  location                   = azurerm_resource_group.devops_rg.location
  sku_name                   = "standard"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled        = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
}

resource "azurerm_key_vault_access_policy" "user_policy" {
  key_vault_id       = azurerm_key_vault.devops_kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = data.azurerm_client_config.current.object_id
  secret_permissions = ["backup", "delete", "get", "list", "purge", "recover", "restore", "set"]
}

resource "azurerm_user_assigned_identity" "devops_id" {
  name                = "${var.prefix}-id"
  resource_group_name = azurerm_resource_group.devops_rg.name
  location            = azurerm_resource_group.devops_rg.location
}

resource "azurerm_key_vault_access_policy" "devops_policy" {
  key_vault_id       = azurerm_key_vault.devops_kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_user_assigned_identity.devops_id.principal_id
  secret_permissions = ["get", "list"]
}

resource "azurerm_role_assignment" "devops_id" {
  scope                = azurerm_resource_group.devops_rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.devops_id.principal_id
}

resource "azurerm_container_group" "agent" {
  name                = "${var.prefix}-container"
  location            = azurerm_resource_group.devops_rg.location
  resource_group_name = azurerm_resource_group.devops_rg.name
  os_type             = "Linux"
  restart_policy      = "Never"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.devops_id.id]
  }

  container {
    name   = "${var.prefix}-agent"
    image  = var.agent-image
    cpu    = "1"
    memory = "1.5"

    environment_variables = {
      "AZP_URL"        = "https://dev.azure.com/chanko/"
      "AZP_AGENT_NAME" = "az-docker-linux"
      "AZP_POOL"       = "AzureContainer"
      "AZ_SECRET_NAME" = "adocontaineragent"
      "AZ_KEY_VAULT"   = "${var.prefix}-kv"
    }

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}
