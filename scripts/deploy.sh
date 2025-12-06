#!/bin/bash

set -e

# Move to script directory
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Move to terraform directory
cd "$SCRIPT_DIR/../terraform"

echo "👉 Running: terraform init"
terraform init

echo "👉 Running: terraform apply -auto-approve"
terraform apply -auto-approve

echo "✔ Terraform init & apply completed successfully"
