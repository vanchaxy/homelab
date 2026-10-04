terraform {
  backend "s3" {
    bucket                      = "tofu-vanchaxy"
    key                         = "homelab/cloudflare.tfstate"
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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.52.0"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.19.30"
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
