variable "laptop_public_ed25519" {
  type = string
}

variable "tailscale" {
  type = object({
    oauth_client_id     = string
    oauth_client_secret = string
  })
  sensitive = true
}

variable "state_passphrase" {
  type      = string
  sensitive = true
}

variable "vyos_apply_mode" {
  type        = string
  default     = "apply"
  description = "apply: push router/AP configs and run Talos/Kubernetes upgrades when they change; dry-run: only report what would change"
}
