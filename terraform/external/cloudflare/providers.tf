terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-cloudflare"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.17.0"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.15.57"
    }
  }
}

provider "infisical" {
  client_id     = var.infisical.client_id
  client_secret = var.infisical.client_secret
}

provider "cloudflare" {
  email   = var.cloudflare.email
  api_key = var.cloudflare.api_key
}
