variable "node" {
  type = object({
    name            = string
    ip              = string
    machine_type    = optional(string, "controlplane")
    ssd_disk_id     = optional(string, "")
    install_disk_id = string
  })
}

variable "extra_patches" {
  type        = list(string)
  default     = []
  description = "Additional machine config patches applied after the generated ones"
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
  description = "ID of something that must finish before this node's config is applied"
}
