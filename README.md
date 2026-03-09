# Gemini Enterprise Setup

This repository contains the Terraform code to set up Gemini Enterprise for a group of users following Google Cloud best practices. Trilo AI provides these templates to simplify the deployment of Gemini Enterprise Connectors and search indexing services.

## Setup Steps

### 1. Update Configuration
Update the variables with your environment-specific values in the `terraform.tfvars` file:
```hcl
project_id                   = "your-gcp-project-id"
region                       = "global"
expected_organization_domain = "your-gcp-org-domain"
org_gemini_users             = "org-user1@your-gcp-org-domain,org-user2@your-gcp-org-domain,..."
```

### 2. Run Deployment Script
We provide an automated script that securely enables the required APIs on your project, initializes Terraform, and applies the configuration automatically.

From your terminal in the root of the project, run:
```bash
./deploy_gemini_enterprise.sh
```

**Note:** If you are redeploying to a completely new project and want to discard the previous state, you can run it with the `--new-project` flag:
```bash
./deploy_gemini_enterprise.sh --new-project
```

### 3. Access the Application
Once the deployment succeeds, the terminal will output a `gemini_enterprise_apps_url`.

**IMPORTANT:** Copy this link and open it in the **same browser session** where you are currently authenticated to the Google Cloud Console. This will take you directly to the Search Engine App created for Gemini Enterprise.

### Managing Access Let on
To add or remove users to Gemini Enterprise, simply modify the membership of the Organization Users (`org_gemini_users`) inside your Google Identity directory. Since Terraform manages IAM on the group level, you do not need to rerun Terraform for individual user modifications.


## Prerequisites
> [!IMPORTANT]
> It is highly advisable to run this setup on **macOS** or **Ubuntu**.

### 1. Terraform (`>= 1.3.0`)
- **macOS (Homebrew):** 
  ```bash
  brew tap hashicorp/tap && brew install hashicorp/tap/terraform
  ```
- **Ubuntu:**
  ```bash
  sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
  wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt-get update && sudo apt-get install terraform
  ```

### 2. Google Cloud SDK (`gcloud`)
Install and authenticate via `gcloud`.
- **macOS (Homebrew):** 
  ```bash
  brew install --cask google-cloud-sdk
  ```
- **Ubuntu:**
  ```bash
  sudo apt-get update && sudo apt-get install apt-transport-https ca-certificates gnupg curl
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
  sudo apt-get update && sudo apt-get install google-cloud-cli
  ```
Once installed, authenticate your session: 
```bash
gcloud auth login
gcloud auth application-default login
```

### 3. Organization Users
Ensure the target Organization Users (e.g., `org_user1@yourdomain,org_user2@yourdomain`) already exists in your Google Identity directory.

### 4. Service Account
Create a service account with `roles/discoveryengine.admin` and `roles/resourcemanager.projectIamAdmin` for **Service Account Impersonation**. You will also need permission to impersonate this service account (`roles/iam.serviceAccountTokenCreator`).

### 5. Support & Feedback
For further assistance or to provide feedback, please contact Trillo AI support at support@trillo.ai.


