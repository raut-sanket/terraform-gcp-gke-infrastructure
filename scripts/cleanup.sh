#!/usr/bin/env bash
set -euo pipefail

# Teardown script — destroys all Terraform-managed resources
# Use with caution. This is irreversible.

ENV="${1:?Usage: cleanup.sh <environment> (production|staging)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_DIR="$SCRIPT_DIR/../environments/$ENV"

if [[ ! -d "$ENV_DIR" ]]; then
  echo "ERROR: Environment directory not found: $ENV_DIR"
  exit 1
fi

echo "WARNING: This will destroy ALL resources in the '$ENV' environment."
echo "Press Ctrl+C within 10 seconds to cancel..."
sleep 10

cd "$ENV_DIR"

echo "==> Running terraform destroy for $ENV..."
terraform destroy -auto-approve

echo "==> Cleanup complete for $ENV."
