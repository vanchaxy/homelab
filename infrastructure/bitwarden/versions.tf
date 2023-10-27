terraform {
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.7.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.9.0"
    }
  }
}

provider "bitwarden" {
  email           = var.bitwarden_email
  master_password = var.bitwarden_password
}

provider "kubernetes" {}
