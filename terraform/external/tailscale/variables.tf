variable "tailscale" {
  type = object({
    oauth_client_id     = string
    oauth_client_secret = string
  })
  sensitive = true
}
