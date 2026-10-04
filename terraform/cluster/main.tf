locals {
  cluster = {
    name               = "talos-homelab"
    endpoint           = "10.10.60.201"
    talos_version      = "v1.11.3"
    kubernetes_version = "v1.34.2"
  }

  nodes = {
    mars = {
      name            = "mars"
      ip              = "10.10.60.201"
      ssd_disk_id     = "nvme-SAMSUNG_MZVLB256HAHQ-000H7_S426NX0M109347"
      install_disk_id = "ata-KINGSTON_SA400S37480G_50026B7282642F76"
    }
    jupiter = {
      name            = "jupiter"
      ip              = "10.10.60.202"
      ssd_disk_id     = "nvme-CT2000P3PSSD8_2443E990D502"
      install_disk_id = "ata-KINGSTON_SA400S37240G_50026B7785719E80"
    },
    saturn = {
      name            = "saturn"
      ip              = "10.10.60.203"
      ssd_disk_id     = "nvme-CT2000P3PSSD8_2443E990D4E6"
      install_disk_id = "ata-KINGSTON_SA400S37240G_50026B778571955D"
    }
  }

  routers = {
    home = "10.10.20.1"
    vps  = "202.61.245.36"
  }

  # renovate: datasource=custom.vyos-stream depName=vyos-stream
  vyos_version = "2026.03"
}

module "vyos" {
  source = "./vyos"

  laptop_public_ed25519 = var.laptop_public_ed25519
}

module "talos" {
  source = "./talos"

  cluster   = local.cluster
  nodes_ips = [for k, v in local.nodes : v.ip]
}

module "node-mars" {
  source = "./node"

  cluster = local.cluster
  node    = local.nodes.mars

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-jupiter" {
  source = "./node"

  cluster = local.cluster
  node    = local.nodes.jupiter

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-saturn" {
  source = "./node"

  cluster = local.cluster
  node    = local.nodes.saturn

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "tailscale" {
  source = "./tailscale"
}

import {
  to = module.tailscale.tailscale_acl.this
  id = "acl"
}

import {
  to = module.tailscale.tailscale_dns_configuration.this
  id = "dns_configuration"
}
