terraform {
  backend "s3" {
    bucket                      = "tofu-vanchaxy"
    key                         = "homelab/cluster.tfstate"
    region                      = "eu-central-003"
    endpoints                   = { s3 = "https://s3.eu-central-003.backblazeb2.com" }
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_s3_checksum            = true
  }

  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    state {
      method   = method.aes_gcm.state
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }

  required_providers {
    external = {
      source  = "hashicorp/external"
      version = "2.4.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
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
