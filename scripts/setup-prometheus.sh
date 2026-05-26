#!/bin/bash

# Install Prometheus and Grafana on AKS

set -e

echo "📊 Installing Prometheus and Grafana..."

# Add Prometheus community Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create monitoring namespace
kubectl create namespace prometheus || true

# Install kube-prometheus-stack
echo "⏳ Installing kube-prometheus-stack..."
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace prometheus \
  --set prometheus.prometheusSpec.retention=7d \
  --set grafana.adminPassword=prom-operator

echo "⏳ Waiting for Prometheus to be ready..."
kubectl rollout status statefulset/prometheus-prometheus -n prometheus --timeout=5m

echo ""
echo "✅ Prometheus and Grafana installed successfully!"
echo ""
echo "📊 To access Prometheus:"
echo "kubectl port-forward -n prometheus svc/prometheus-operated 9090:9090"
echo "Then visit: http://localhost:9090"
echo ""
echo "📈 To access Grafana:"
echo "kubectl port-forward -n prometheus svc/prometheus-grafana 3000:80"
echo "Then visit: http://localhost:3000"
echo "Username: admin"
echo "Password: prom-operator"
echo ""
