variable "infisical" {
  type = object({
    client_id     = string
    client_secret = string
  })
}

variable "state_passphrase" {
  type      = string
  sensitive = true
}
