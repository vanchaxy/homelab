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
      version = "2.17.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
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
