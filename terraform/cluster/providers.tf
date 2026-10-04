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
      version = "0.11.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.29.2"
    }
  }
}

provider "tailscale" {
  oauth_client_id     = var.tailscale.oauth_client_id
  oauth_client_secret = var.tailscale.oauth_client_secret
}
