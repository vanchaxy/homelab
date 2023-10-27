terraform {
  required_providers {
    hcloud = {
      source = "hetznercloud/hcloud"
    }
  }
  required_version = ">= 0.14"
}

provider "hcloud" {
  token = var.hcloud_token
}
