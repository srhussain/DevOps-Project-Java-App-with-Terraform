#!/bin/bash
set -e

# -------------------------
# Terraform Apply Script from scripts/ folder
# -------------------------

# Ensure Terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Please install Terraform before running this script."
    exit 1
fi

# Navigate to Terraform directory
TERRAFORM_DIR="../terraform"
if [ ! -d "$TERRAFORM_DIR" ]; then
    echo "Terraform directory not found at $TERRAFORM_DIR"
    exit 1
fi
cd "$TERRAFORM_DIR"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "Validating Terraform configuration..."
terraform validate

# Apply Terraform configuration
echo "Applying Terraform configuration..."
terraform apply -auto-approve

echo "Terraform apply completed successfully."
