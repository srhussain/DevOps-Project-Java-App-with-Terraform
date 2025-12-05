#!/bin/bash

set -e

# Move to script directory
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

# Move to terraform directory
cd "$SCRIPT_DIR/../terraform"

echo "👉 Running: terraform destroy -auto-approve"
terraform destroy -auto-approve

echo "✔ Terraform destroy completed successfully"
