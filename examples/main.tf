provider "vcfa" {
  url                  = var.vcfa_url
  org                  = var.vcfa_organization
  api_token            = var.vcfa_refresh_token
  allow_unverified_ssl = var.insecure
  auth_type            = "api_token"
}

module "org" {
  source = "../"

  name         = var.org_name
  display_name = var.org_display_name
  description  = var.org_description
  is_enabled   = var.is_enabled

  org_settings = var.org_settings

  local_admin          = var.local_admin
  local_admin_password = var.local_admin_password

  oidc               = var.oidc
  oidc_client_secret = var.oidc_client_secret
}
