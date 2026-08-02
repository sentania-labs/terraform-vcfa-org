variable "name" {
  type        = string
  description = "Machine name of the VCFA organization (immutable after creation)."
}

variable "display_name" {
  type        = string
  description = "Human-friendly display name of the organization shown in the VCFA UI."
}

variable "description" {
  type        = string
  description = "Description for the organization."
  default     = ""
}

variable "is_enabled" {
  type        = bool
  description = "Whether the organization is enabled. Disabled orgs block all tenant login, including OIDC."
  default     = true
}

variable "org_settings" {
  type = object({
    can_create_subscribed_libraries        = optional(bool, false)
    can_subscribe_to_third_party_libraries = optional(bool, false)
    quarantine_content_library_items       = optional(bool, true)
  })
  description = "Org-wide content library settings. Every org gets a vcfa_org_settings resource; this is not optional in the module (it always follows org creation), only its values are tunable. Defaults are the conservative choice: no publish/subscribe federation, quarantine on."
  default     = {}
}

variable "local_admin" {
  type = object({
    username = string
    role_ids = set(string)
  })
  description = "Local (non-federated) admin user to create in the org, e.g. a break-glass account. Set to null to skip creating one. The account's password is supplied separately via var.local_admin_password."
  default     = null
}

variable "local_admin_password" {
  type        = string
  description = "Password for the local admin user described in var.local_admin. Required whenever var.local_admin is set. No default: passwords are never shipped with a placeholder value, supply via TF_VAR_local_admin_password or an equivalent secret-injection mechanism, never in a checked-in tfvars file."
  sensitive   = true
  default     = null

  validation {
    condition     = var.local_admin == null || (var.local_admin_password != null && var.local_admin_password != "")
    error_message = "local_admin_password is required whenever local_admin is set (a local admin user cannot be created without a password)."
  }
}

variable "oidc" {
  type = object({
    client_id              = string
    wellknown_endpoint     = string
    scopes                 = optional(set(string), ["openid", "profile", "email", "group"])
    ui_button_label        = optional(string, "VCF SSO")
    max_clock_skew_seconds = optional(number, 60)
    prefer_id_token        = optional(bool, false)
    groups = optional(list(object({
      name = string
      role = string
    })), [])
  })
  description = <<-EOT
    OIDC federation to vIDB, the golden pattern this module exists to enforce. Set to null
    to leave the org unfederated (local users only). The subject claim (preferred_username)
    and groups claim (group_names) are NOT configurable here: they are hard-coded in this
    module because getting either wrong silently breaks login (subject=sub compares against
    an opaque IdP UUID instead of a username; subject=acct hits a known vIDB double-UPN bug).

    `groups` records the AD group -> VCFA role mapping this org expects to import. The
    vmware/vcfa provider (as of v1.2.0) has no resource to create that import itself, so this
    module validates and exposes it (see output.oidc_group_role_map) for manual reconciliation
    or a future resource, rather than silently dropping it.
  EOT
  default     = null

  validation {
    condition     = var.oidc == null || contains(var.oidc.scopes, "group")
    error_message = "oidc.scopes must include \"group\": without it the token carries no group claims and AD-group login cannot work, even though user login will appear fine."
  }

  validation {
    condition     = var.oidc == null || alltrue([for g in var.oidc.groups : g.name == lower(g.name)])
    error_message = "oidc.groups[].name must be lowercase. VCFA's group-import login match is case-sensitive against the AD group name; an uppercase mismatch (e.g. \"labAdmins\" vs \"labadmins\") silently breaks login for every member of that group instead of raising an error."
  }
}

variable "oidc_client_secret" {
  type        = string
  description = "Client secret for the OIDC registration described in var.oidc. Required whenever var.oidc is set (pass a placeholder value via TF_VAR when oidc is null; the variable itself is always declared required). No default: this secret is not recoverable from VCFA once set, it lives in vIDB / the Ops locker, and secrets are never given a default value here. Supply via TF_VAR_oidc_client_secret or an equivalent secret-injection mechanism, never in a checked-in tfvars file."
  sensitive   = true

  validation {
    condition     = var.oidc == null || (var.oidc_client_secret != null && var.oidc_client_secret != "")
    error_message = "oidc_client_secret is required whenever oidc is set (OIDC federation cannot be created without a client secret)."
  }
}
