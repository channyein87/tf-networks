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
