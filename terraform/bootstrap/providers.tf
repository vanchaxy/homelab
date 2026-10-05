terraform {
  backend "s3" {
    bucket                      = "tofu-vanchaxy"
    key                         = "homelab/bootstrap.tfstate"
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
    helm = {
      source  = "hashicorp/helm"
      version = "3.3.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.3.1"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}


provider "helm" {
  kubernetes = {
    config_path = "${path.module}/../output/kube-config.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/../output/kube-config.yaml"
}
