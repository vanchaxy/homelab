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
    "kube0" : { master : true, type : "cpx31" },
  }
}

variable "ansible_inventory_path" {
  type = string
}
