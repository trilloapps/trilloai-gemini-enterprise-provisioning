data "google_organization" "target_org" {
  domain = var.expected_organization_domain
}

data "google_project" "current_project" {
  project_id = var.project_id
}

# 1. Enable Required APIs (Dependencies)
resource "google_project_service" "discovery_engine_api" {
  project            = var.project_id
  service            = "discoveryengine.googleapis.com"
  disable_on_destroy = false

  lifecycle {
    precondition {
      condition     = data.google_project.current_project.org_id == data.google_organization.target_org.org_id
      error_message = "The specified GCP project (${var.project_id}) does not belong to the expected organization domain (${var.expected_organization_domain}). Setup aborted."
    }
  }
}

resource "google_project_service" "gemini_api" {
  project            = var.project_id
  service            = "cloudaicompanion.googleapis.com"
  disable_on_destroy = false
}

resource "random_id" "gemini_suffix" {
  byte_length = 4
}

# Create a search engine for Gemini Enterprise using REST API via null_resource
# This is required because the Terraform provider currently does not support the "appType" attribute
resource "null_resource" "gemini_app" {
  triggers = {
    engine_id  = "gemini-enterprise-${random_id.gemini_suffix.hex}"
    project_id = var.project_id
    location   = var.region
  }

  provisioner "local-exec" {
    command = <<EOT
      # Wait a brief moment to ensure Discovery Engine API is fully propagated
      sleep 10
      curl -s --fail-with-body -X POST \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "Content-Type: application/json" \
        -H "x-goog-user-project: ${var.project_id}" \
        "https://${var.region}-discoveryengine.googleapis.com/v1alpha/projects/${var.project_id}/locations/${var.region}/collections/default_collection/engines?engineId=${self.triggers.engine_id}" \
        -d '{
          "displayName": "Gemini Enterprise Search App",
          "solutionType": "SOLUTION_TYPE_SEARCH",
          "industryVertical": "GENERIC",
          "searchEngineConfig": {
            "searchTier": "SEARCH_TIER_ENTERPRISE",
            "searchAddOns": ["SEARCH_ADD_ON_LLM"],
            "requiredSubscriptionTier": "SUBSCRIPTION_TIER_SEARCH_AND_ASSISTANT"
          },
          "appType": "APP_TYPE_INTRANET"
        }'
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      curl -s --fail-with-body -X DELETE \
        -H "Authorization: Bearer $(gcloud auth print-access-token)" \
        -H "x-goog-user-project: ${self.triggers.project_id}" \
        "https://${self.triggers.location}-discoveryengine.googleapis.com/v1alpha/projects/${self.triggers.project_id}/locations/${self.triggers.location}/collections/default_collection/engines/${self.triggers.engine_id}"
    EOT
  }

  depends_on = [
    google_project_service.discovery_engine_api
  ]
}

locals {
  # Split the comma-separated string into a list and prefix with "user:"
  gemini_users = [for email in split(",", var.org_gemini_users) : "user:${trimspace(email)}"]
}

# 3. Manage user access & Essential IAM Roles
# Assign roles/discoveryengine.viewer to the users
resource "google_project_iam_binding" "discovery_engine_viewer" {
  project = var.project_id
  role    = "roles/discoveryengine.viewer"

  members = local.gemini_users

  lifecycle {
    precondition {
      condition     = alltrue([for email in split(",", var.org_gemini_users) : endswith(trimspace(email), "@${var.expected_organization_domain}")])
      error_message = "All provided email addresses in org_gemini_users must belong to the expected organization domain: ${var.expected_organization_domain}"
    }
  }
}

# Assign roles/cloudaicompanion.user to the users
resource "google_project_iam_binding" "gemini_user" {
  project = var.project_id
  role    = "roles/cloudaicompanion.user"

  members = local.gemini_users
}

# 4. Create a Service Account for future Terraform executions
resource "google_service_account" "terraform_sa" {
  account_id   = "gemini-terraform-sa"
  display_name = "Terraform Service Account for Gemini Ent"
  project      = var.project_id
}

# Assign roles to the Terraform SA
locals {
  sa_roles = [
    "roles/discoveryengine.admin",
    "roles/resourcemanager.projectIamAdmin",
    "roles/serviceusage.serviceUsageAdmin"
  ]
}

resource "google_project_iam_member" "terraform_sa_roles" {
  for_each = toset(local.sa_roles)
  project  = var.project_id
  role     = each.value
  member   = "serviceAccount:${google_service_account.terraform_sa.email}"
}
