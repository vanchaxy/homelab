variable "infisical" {
  type = object({
    client_id     = string
    client_secret = string
    env_slug      = string
    workspace_id  = string
  })
}
