locals {
  cluster = {
    name     = "talos-homelab"
    endpoint = "10.10.60.201"
    # renovate: datasource=github-releases depName=siderolabs/talos
    talos_version = "v1.14.2"
    # renovate: datasource=github-releases depName=kubernetes/kubernetes
    kubernetes_version = "v1.37.1"
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

  neptune_network = true
  neptune_node    = false
  neptune = {
    name            = "neptune"
    ip              = "10.10.60.204"
    machine_type    = "worker"
    install_disk_id = "nvme-Apacer_AS2280P4_256GB_AA202601120937"
  }

  routers = {
    home = "10.10.20.1"
    vps  = "202.61.245.36:47823"
  }

  ci_public_ed25519 = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJJrSnA851nBzfeHUNWDvUKuoVO4HBiqLMJ/DpOA2EK homelab-ci"

  # renovate: datasource=custom.vyos-stream depName=vyos-stream
  vyos_version = "2026.03"
}

module "vyos" {
  source = "./vyos"

  neptune_enabled = local.neptune_network

  laptop_public_ed25519 = var.laptop_public_ed25519
  ci_public_ed25519     = local.ci_public_ed25519
}

module "talos" {
  source = "./talos"

  cluster   = local.cluster
  nodes_ips = [for k, v in local.nodes : v.ip]
}

module "node-mars" {
  source = "./node"

  after = terraform_data.upgrade_k8s.id

  cluster = local.cluster
  node    = local.nodes.mars

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-jupiter" {
  source = "./node"

  after = module.node-mars.talos_machine_configuration_apply_id

  cluster = local.cluster
  node    = local.nodes.jupiter

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-saturn" {
  source = "./node"

  after = module.node-jupiter.talos_machine_configuration_apply_id

  cluster = local.cluster
  node    = local.nodes.saturn

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-neptune" {
  source = "./node"
  count  = local.neptune_node ? 1 : 0

  after = module.node-saturn.talos_machine_configuration_apply_id

  cluster = local.cluster
  node    = local.neptune

  talos_installer_url = module.talos.installer_url
  extra_patches       = [file("${path.module}/node/nas-patch.yaml")]

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

module "gl" {
  source = "./gl"

  authorized_keys = [var.laptop_public_ed25519, local.ci_public_ed25519]
}
