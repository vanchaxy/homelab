terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-authentik"
    }
  }

  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.12.1"
    }
    infisical = {
      source  = "Infisical/infisical"
      version = "0.15.3"
    }
  }
}

provider "infisical" {
  client_id     = var.infisical.client_id
  client_secret = var.infisical.client_secret
}

data "infisical_secrets" "authentik" {
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/authentik/"
}

provider "authentik" {
  url   = "https://auth.ivanchenko.io"
  token = data.infisical_secrets.authentik.secrets["bootstrap_token"].value
}
