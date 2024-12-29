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
    email      = string
    api_key    = string
    account_id = string
  })
}
