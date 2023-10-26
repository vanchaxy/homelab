variable "hcloud_token" {
  sensitive = true
}

variable "ssh_key_name" {
  default = "default"
}

variable "ssh_key_path" {
  default = "~/.ssh/id_ed25519.pub"
}

variable "location" {
  default = "ash"
}

variable "image" {
  default = "fedora-38"
}

variable "hosts" {
  default = {
    "kube1" : { master : true, type : "cpx11" },
    "kube2" : { master : true, type : "cpx11" },
    "kube3" : { master : false, type : "cpx11" },
  }
}

variable "vpn_address_range" {
  default = "10.8.0.0/24"
}

variable "vpn_first_host_number" {
  default = 201
}

variable "ansible_inventory_path" {
  type = string
}
