variable "project_id" {
  description = "The Google Cloud Project ID"
  type        = string
}

variable "region" {
  description = "The region for the Gemini enterprise resources"
  type        = string
  default     = "global"
}


variable "org_gemini_users" {
  description = "Comma-separated list of user emails to grant access to Gemini Enterprise"
  type        = string
}

variable "expected_organization_domain" {
  description = "The expected domain of the Google Cloud Organization (e.g., example.com)"
  type        = string
}



