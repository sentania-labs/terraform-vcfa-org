variable "org_name" {
  type        = string
  description = "Machine name of the VCFA organization"
}

variable "org_display_name" {
  type        = string
  description = "Display name of the VCFA organization"
}

variable "org_description" {
  type        = string
  description = "Description for the organization"
  default     = ""
}

variable "is_enabled" {
  type        = bool
  description = "Whether the organization is enabled"
  default     = true
}

variable "org_settings" {
  type = object({
    can_create_subscribed_libraries        = optional(bool, false)
    can_subscribe_to_third_party_libraries = optional(bool, false)
    quarantine_content_library_items       = optional(bool, true)
  })
  description = "Org-wide content library settings"
  default     = {}
}

variable "local_admin" {
  type = object({
    username = string
    role_ids = set(string)
  })
  description = "Local admin user to create in the org, or null to skip"
  default     = null
}

variable "local_admin_password" {
  type        = string
  description = "Password for the local admin user, required when local_admin is set"
  sensitive   = true
  default     = null
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
  description = "OIDC federation to vIDB, or null to leave the org unfederated"
  # Defaults to a sample federation (not null) so the module's local/output evaluation over
  # var.oidc.groups, including a group repeated across roles, is exercised without extra input.
  # Override client_id/wellknown_endpoint/groups (or pass oidc = null) for a real apply.
  default = {
    client_id          = "26e6f555-7de3-456f-a23c-143a16fe6bb3"
    wellknown_endpoint = "https://vcf-lab-idb.int.sentania.net/acs/t/CUSTOMER/.well-known/openid-configuration"
    groups = [
      # Same group, two roles: expressed by repeating the group name once per role.
      { name = "labadmins", role = "Organization Administrator" },
      { name = "labadmins", role = "Service Broker Admin" },
      { name = "labadmins", role = "Assembler" },
    ]
  }
}

variable "oidc_client_secret" {
  type        = string
  description = "Client secret for the OIDC registration described in var.oidc"
  sensitive   = true
}

########################################
# General VCF-A Configuration
########################################

/**
 * vcfa_url
 * URL of the VCF-A (Aria Automation) endpoint.
 */
variable "vcfa_url" {
  type = string
}

variable "vcfa_organization" {
  type        = string
  description = "The VCFA Organization"
}

/**
 * vcfa_refresh_token
 * Refresh token used for authentication to the VCF-A API.
 * Marked sensitive to avoid logging/output exposure.
 */
variable "vcfa_refresh_token" {
  type      = string
  sensitive = true
}

/**
 * insecure
 * Whether to skip SSL certificate verification when connecting
 * to the VCF-A API (typically true for lab environments).
 */
variable "insecure" {
  type    = bool
  default = true
}
