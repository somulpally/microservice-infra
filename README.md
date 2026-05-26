# Microservice Infrastructure as Code

Terraform configuration for deploying Azure AKS cluster with monitoring and ArgoCD setup.

## 🏗️ What This Creates

- **Azure Resource Group** - Container for all resources
- **Azure Container Registry (ACR)** - Private container registry (FREE tier)
- **AKS Cluster** - Kubernetes cluster with 3 nodes (FREE for first cluster)
- **ArgoCD** - GitOps deployment controller
- **Prometheus + Grafana** - Monitoring stack
- **Network Security** - Proper networking and NSGs

## 💰 Cost (First Year)

```
AKS Cluster:        FREE (first cluster)
ACR Basic:          FREE (10 GB/month)
Node VMs (3x):      ~$0.25/hour each
────────────────────────────────────────
TOTAL:              ~$185/month for nodes only
                    (Completely FREE if using Azure free credits)
```

## 📋 Prerequisites

- Azure subscription (free tier available)
- Terraform >= 1.0
- Azure CLI installed and configured
- `kubectl` installed

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "<subscription-id>"
```

## 🚀 Quick Start

### 1. Initialize Terraform

```bash
cd terraform
terraform init
```

### 2. Create terraform.tfvars

```hcl
# terraform/terraform.tfvars
project_name        = "microservice"
env                  = "dev"
location             = "eastus"
node_count           = 3
vm_size              = "Standard_B2s"  # Cheap for learning
```

### 3. Plan and Apply

```bash
# Review what will be created
terraform plan

# Create all resources
terraform apply
```

### 4. Get kubeconfig

```bash
# Configure kubectl
az aks get-credentials \
  --resource-group microservice-rg-dev \
  --name microservice-aks-dev

# Verify connection
kubectl get nodes
```

## 📁 Directory Structure

```
microservice-infra/
├── terraform/
│   ├── main.tf                 # Main resource definitions
│   ├── variables.tf            # Input variables
│   ├── outputs.tf              # Output values
│   ├── versions.tf             # Provider versions
│   └── terraform.tfvars.example# Example variables
├── scripts/
│   ├── setup-argocd.sh         # Install ArgoCD
│   ├── setup-prometheus.sh     # Install Prometheus
│   └── setup-acr-secret.sh     # Configure ACR access
└── README.md
```

## 🔧 Key Resources

### Azure Resource Group
```hcl
resource "azurerm_resource_group" "main" {
  name     = "${var.project_name}-rg-${var.env}"
  location = var.location
}
```

### AKS Cluster
```hcl
resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.project_name}-aks-${var.env}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.project_name}-${var.env}"
  
  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }
  
  identity {
    type = "SystemAssigned"
  }
}
```

### Azure Container Registry
```hcl
resource "azurerm_container_registry" "main" {
  name                = "${replace(var.project_name, "-", "")}acr${var.env}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"  # FREE tier!
  admin_enabled       = true
}
```

## 📝 Configuration Variables

### Required
- `project_name` - Project name (used for naming)
- `env` - Environment (dev, staging, prod)
- `location` - Azure region

### Optional
- `node_count` - Number of worker nodes (default: 3)
- `vm_size` - VM size (default: Standard_B2s)
- `kubernetes_version` - K8s version
- `network_plugin` - CNI plugin (azure or kubenet)

## 🔨 Post-Deployment Setup

### 1. Install ArgoCD

```bash
# Run setup script
bash scripts/setup-argocd.sh

# Get ArgoCD password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access: http://localhost:8080
```

### 2. Install Prometheus + Grafana

```bash
# Run setup script
bash scripts/setup-prometheus.sh

# Access Prometheus
kubectl port-forward -n prometheus svc/prometheus 9090:9090

# Access Grafana
kubectl port-forward -n prometheus svc/grafana 3000:3000
# Default: admin/prom-operator
```

### 3. Configure ACR Secret

```bash
# Run setup script
bash scripts/setup-acr-secret.sh

# Verify
kubectl get secret acr-secret -n microservice
```

## 📊 Outputs

After `terraform apply`, you'll get:

```
aks_cluster_name = "microservice-aks-dev"
aks_fqdn = "microservice-dev.eastus.azmk8s.io"
acr_login_server = "microserviceacrdev.azurecr.io"
resource_group_name = "microservice-rg-dev"
kubernetes_cluster_id = "/subscriptions/..."
```

## 🗑️ Cleanup

**⚠️ WARNING: This will delete all resources!**

```bash
terraform destroy
```

## 🚨 Troubleshooting

### AKS Cluster Creation Fails
```bash
# Check quota
az vm list-usage --location eastus
```

### Cannot Connect to Cluster
```bash
# Refresh kubeconfig
az aks get-credentials --resource-group <rg> --name <cluster-name> --overwrite-existing
```

### Node Pool Issues
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>
```

## 📚 Related Repositories

- **microservice-app** - Application source code
- **microservice-k8s-config** - Kubernetes manifests

## 📄 License

MIT License
