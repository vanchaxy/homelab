variable "infisical" {
  type = object({
    client_id     = string
    client_secret = string
    env_slug      = string
    workspace_id  = string
  })
}

variable "cloudflare" {
  type = object({
    api_token  = string
    account_id = string
  })
}

variable "state_passphrase" {
  type      = string
  sensitive = true
}
