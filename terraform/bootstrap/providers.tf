terraform {
  cloud {
    organization = "ivanchenko"

    workspaces {
      name = "homelab-bootstrap"
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
  kubernetes {
    config_path = "${path.module}/../output/kube-config.yaml"
  }
}

provider "kubectl" {
  config_path = "${path.module}/../output/kube-config.yaml"
}
