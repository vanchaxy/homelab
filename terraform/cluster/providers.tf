terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-cluster"
    }
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.77.0"
    }
        talos = {
      source  = "siderolabs/talos"
      version = "0.8.0"
    }
  }
}

provider "proxmox" {
  alias    = "mars"
  endpoint = "https://192.168.50.201:8006/"
  insecure = true

  username = var.proxmox.username
  password = var.proxmox.password
}

provider "proxmox" {
  alias    = "jupiter"
  endpoint = "https://192.168.50.202:8006/"
  insecure = true

  username = var.proxmox.username
  password = var.proxmox.password
}

provider "proxmox" {
  alias    = "saturn"
  endpoint = "https://192.168.50.203:8006/"
  insecure = true

  username = var.proxmox.username
  password = var.proxmox.password
}
