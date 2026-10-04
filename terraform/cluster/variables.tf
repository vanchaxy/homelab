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
