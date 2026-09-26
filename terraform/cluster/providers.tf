terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-cluster"
    }
  }

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
    }
  }
}
