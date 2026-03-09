#!/bin/bash
set -e

# Make sure we are in the correct directory (the one containing terraform.tfvars)
if [ ! -f "terraform.tfvars" ]; then
    echo "Error: terraform.tfvars not found in the current directory."
    echo "Please run this script from the terraform project root."
    exit 1
fi

echo "Extracting project_id from terraform.tfvars..."
PROJECT_ID=$(grep '^project_id' terraform.tfvars | awk -F'"' '{print $2}')

if [ -z "$PROJECT_ID" ]; then
  echo "Error: project_id not found in terraform.tfvars."
  exit 1
fi

echo "Detected Project ID: $PROJECT_ID"
NEW_PROJECT=false

for arg in "$@"; do
  if [ "$arg" == "--new-project" ] || [ "$arg" == "-n" ]; then
    NEW_PROJECT=true
  fi
done

echo "--------------------------------------------------------"

echo "Step 1: Checking for new project flag..."
if [ "$NEW_PROJECT" = true ]; then
  echo "New project flag detected. Cleaning up previous Terraform state and cache..."
  rm -rf .terraform terraform.tfstate terraform.tfstate.backup .terraform.lock.hcl
  echo "Cleanup complete."
else
  echo "No --new-project flag provided. Keeping existing Terraform state."
fi
echo "--------------------------------------------------------"

echo "Step 2: Enabling required Google Cloud APIs for exactly this project..."
echo "(This allows Terraform to read/modify resources on the fresh project)"
gcloud services enable cloudresourcemanager.googleapis.com iam.googleapis.com --project "$PROJECT_ID"
echo "APIs enabled."
echo "--------------------------------------------------------"

echo "Step 3: Initializing Terraform for the fresh state..."
terraform init
echo "Initialization complete."
echo "--------------------------------------------------------"

echo "Step 4: Running terraform apply..."
terraform apply -auto-approve

echo "--------------------------------------------------------"
echo "Deployment successfully completed for $PROJECT_ID!"
