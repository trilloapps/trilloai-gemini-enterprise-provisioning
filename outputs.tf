output "discovery_engine_search_engine_id" {
  description = "The ID of the Search Engine"
  value       = "gemini-enterprise-${random_id.gemini_suffix.hex}"
}

output "enterprise_application_name" {
  description = "The display name of the Gemini Enterprise application"
  value       = "Gemini Enterprise Search App"
}

output "gemini_enterprise_apps_url" {
  description = "The URL to view the provisioned app in the Gemini Enterprise Console"
  value       = "https://console.cloud.google.com/gemini-enterprise/apps?project=${var.project_id}"
}

output "terraform_service_account_email" {
  description = "The email of the created Terraform Service Account that can be used for future CI/CD runs"
  value       = google_service_account.terraform_sa.email
}
