variable "nodes" {
  type = map(object({
    node = object({
      wg_ip            = string
      vps_wg_ip        = string
      vps_wg_interface = string
      vps_wg_port      = string
    })
    pubkey = string
  }))
}

variable "laptop_public_ed25519" {
  type = string
}

variable "forward_ip" {
  type = string
}
