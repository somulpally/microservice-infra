# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-${var.env}"
  location = var.location

  tags = merge(var.tags, {
    environment = var.env
  })
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "${var.project_name}-vnet-${var.env}"
  address_space       = ["10.0.0.0/8"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = var.tags
}

# Subnet
resource "azurerm_subnet" "internal" {
  name                 = "${var.project_name}-subnet-${var.env}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.240.0.0/16"]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.env}"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "default"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = azurerm_subnet.internal.id
    type                = "VirtualMachineScaleSets"
    enable_auto_scaling = true
    min_count           = var.node_count
    max_count           = var.node_count + 2
    max_pods            = 110
  }

  # Managed Identity
  identity {
    type = "SystemAssigned"
  }

  # Network Configuration
  network_profile {
    network_plugin    = var.network_plugin
    service_cidr      = "10.0.0.0/16"
    dns_service_ip    = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  # RBAC
  role_based_access_control_enabled = true

  # Cluster Addons
  http_application_routing_enabled = false
  oms_agent {
    msi_auth_for_monitoring_enabled = true
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.main.id
  }

  tags = merge(var.tags, {
    environment = var.env
  })

  depends_on = [
    azurerm_role_assignment.aks_vnet
  ]
}

# AKS Cluster - Network Role Assignment
resource "azurerm_role_assignment" "aks_vnet" {
  scope              = azurerm_virtual_network.main.id
  role_definition_name = "Network Contributor"
  principal_id       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# AKS Cluster - ACR Role Assignment
resource "azurerm_role_assignment" "aks_acr" {
  scope              = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id       = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.project_name}-law-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"

  tags = var.tags
}

# Container Registry
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}acr${var.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = merge(var.tags, {
    environment = var.env
  })
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "${var.project_name}-nsg-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Subnet - NSG Association
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.main.id
}
