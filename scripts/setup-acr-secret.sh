#!/bin/bash

# Setup ACR secret for AKS to pull images

set -e

echo "🔐 Setting up ACR credentials..."

# Get ACR details from Terraform outputs
REGISTRY_NAME=$(terraform output -raw acr_registry_name)
REGISTRY_USERNAME=$(terraform output -raw acr_admin_username)
REGISTRY_PASSWORD=$(terraform output -raw acr_admin_password)
REGISTRY_SERVER="${REGISTRY_NAME}.azurecr.io"

echo "Registry: $REGISTRY_SERVER"

# Create microservice namespace if it doesn't exist
kubectl create namespace microservice || true

# Create docker registry secret
echo "Creating docker registry secret..."
kubectl create secret docker-registry acr-secret \
  --docker-server=${REGISTRY_SERVER} \
  --docker-username=${REGISTRY_USERNAME} \
  --docker-password=${REGISTRY_PASSWORD} \
  -n microservice || true

echo ""
echo "✅ ACR secret created successfully!"
echo "Secret name: acr-secret"
echo "Namespace: microservice"
echo ""
echo "Update your deployment.yaml imagePullSecrets:"
echo "- name: acr-secret"
echo ""
