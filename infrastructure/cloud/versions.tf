terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab"
    }
  }

  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }

  required_version = ">= 1.1.2"
}

provider "hcloud" {
  token = var.hcloud_token
}
