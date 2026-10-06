variable "node" {
  type = object({
    name            = string
    ip              = string
    ssd_disk_id     = string
    install_disk_id = string
  })
}


variable "machine_secrets" {
  type = any
}

variable "client_configuration" {
  type = any
}

variable "cluster" {
  type = object({
    name               = string
    endpoint           = string
    talos_version      = string
    config_contract    = string
    kubernetes_version = string
  })
  sensitive = true
}

variable "talos_installer_url" {
  type = string
}

variable "after" {
  type        = string
  default     = ""
  description = "ID of something that must finish before this node's config is applied (adds nothing to the endpoint value)"
}
