resource "azurerm_resource_group" "myResourceGroup" {
  name     = "myResourceGroup"
  location = "East US"
}

resource "azurerm_virtual_network" "myVNet" {
  name                = "myVNet"
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  location            = azurerm_resource_group.myResourceGroup.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "frontend" {
  name                 = "frontend"
  resource_group_name  = azurerm_resource_group.myResourceGroup.name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "backend" {
  name                 = "backend"
  resource_group_name  = azurerm_resource_group.myResourceGroup.name
  virtual_network_name = azurerm_virtual_network.myVNet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "myAGPublicIPAddress" {
  name                = "myAGPublicIPAddress"
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  location            = azurerm_resource_group.myResourceGroup.location
  allocation_method   = "Dynamic"
}

#&nbsp;since these variables are re-used - a locals block makes this more maintainable
locals {
  backend_address_pool_name      = "${azurerm_virtual_network.myVNet.name}-beap"
  frontend_port_name             = "${azurerm_virtual_network.myVNet.name}-feport"
  frontend_ip_configuration_name = "${azurerm_virtual_network.myVNet.name}-feip"
  http_setting_name              = "${azurerm_virtual_network.myVNet.name}-be-htst"
  listener_name                  = "${azurerm_virtual_network.myVNet.name}-httplstn"
  request_routing_rule_name      = "${azurerm_virtual_network.myVNet.name}-rqrt"
  redirect_configuration_name    = "${azurerm_virtual_network.myVNet.name}-rdrcfg"
}

resource "azurerm_application_gateway" "network" {
  name                = "example-appgateway"
  resource_group_name = azurerm_resource_group.myResourceGroup.name
  location            = azurerm_resource_group.myResourceGroup.location

  sku {
    name     = "Standard_Small"
    tier     = "Standard"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.frontend.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.myAGPublicIPAddress.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/path1/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }
}
