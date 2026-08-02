resource "vcfa_org" "this" {
  name         = var.name
  display_name = var.display_name
  description  = var.description
  is_enabled   = var.is_enabled
}

# Always created: every org needs its settings resource, only the values are tunable
# (see var.org_settings).
resource "vcfa_org_settings" "this" {
  org_id                                 = vcfa_org.this.id
  can_create_subscribed_libraries        = var.org_settings.can_create_subscribed_libraries
  can_subscribe_to_third_party_libraries = var.org_settings.can_subscribe_to_third_party_libraries
  quarantine_content_library_items       = var.org_settings.quarantine_content_library_items
}

resource "vcfa_org_local_user" "admin" {
  count = var.local_admin != null ? 1 : 0

  org_id   = vcfa_org.this.id
  username = var.local_admin.username
  password = var.local_admin_password
  role_ids = var.local_admin.role_ids
}

# The OIDC golden pattern. subject/groups claims are hard-coded, not variables: they are
# load-bearing and getting either wrong silently breaks login rather than raising an error.
resource "vcfa_org_oidc" "this" {
  count = var.oidc != null ? 1 : 0

  org_id                 = vcfa_org.this.id
  enabled                = true
  client_id              = var.oidc.client_id
  client_secret          = var.oidc_client_secret
  wellknown_endpoint     = var.oidc.wellknown_endpoint
  scopes                 = var.oidc.scopes
  ui_button_label        = var.oidc.ui_button_label
  max_clock_skew_seconds = var.oidc.max_clock_skew_seconds
  prefer_id_token        = var.oidc.prefer_id_token

  claims_mapping {
    subject    = "preferred_username" # never "sub" (opaque IdP UUID) or "acct" (vIDB double-UPN bug)
    groups     = "group_names"        # what VCFA matches imported group names against
    email      = "email"
    full_name  = "name"
    first_name = "given_name"
    last_name  = "family_name"
    roles      = "roles"
  }
}
