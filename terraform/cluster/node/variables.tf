variable "node" {
  type = object({
    name             = string
    ip               = string
    ssd_disk_id      = string
    install_disk_id  = string
    wg_ip            = string
    vps_wg_interface = string
    vps_wg_port      = string
  })
}

variable "vps_wg" {
  type = object({
    ip         = string
    public_key = string
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
    kubernetes_version = string
  })
  sensitive = true
}

variable "talos_installer_url" {
  type = string
}
