#!/usr/bin/env bash
set -euo pipefail

# Post-provision bootstrap for GKE cluster
# Creates namespaces, installs ArgoCD, and configures initial secrets

CLUSTER_NAME="${1:?Usage: init-cluster.sh <cluster-name> <region> <project-id>}"
REGION="${2:?Missing region}"
PROJECT_ID="${3:?Missing project-id}"

echo "==> Fetching cluster credentials..."
gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --region "$REGION" \
  --project "$PROJECT_ID"

echo "==> Creating namespaces..."
NAMESPACES=(argocd monitoring ingress-nginx cert-manager external-secrets)
for ns in "${NAMESPACES[@]}"; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

echo "==> Installing ArgoCD..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for ArgoCD server..."
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s

echo "==> ArgoCD initial admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

echo "==> Cluster bootstrap complete."
echo "    Next steps:"
echo "    1. Change the ArgoCD admin password"
echo "    2. Apply App-of-Apps pattern: kubectl apply -f argocd-app-of-apps.yaml"
echo "    3. Configure external-secrets ClusterSecretStore"
