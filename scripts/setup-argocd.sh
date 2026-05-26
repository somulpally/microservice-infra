#!/bin/bash

# Install ArgoCD on AKS

set -e

echo "🚀 Installing ArgoCD..."

# Create namespace
kubectl create namespace argocd || true

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "⏳ Waiting for ArgoCD to be ready..."
kubectl rollout status deployment/argocd-server -n argocd --timeout=5m

# Get initial password
echo ""
echo "✅ ArgoCD installed successfully!"
echo ""
echo "🔑 Initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
echo ""
echo "🌐 To access ArgoCD UI:"
echo "kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "Then visit: http://localhost:8080"
echo "Username: admin"
echo ""
