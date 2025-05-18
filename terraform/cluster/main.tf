locals {
  cluster = {
    name          = "talos-homelab"
    endpoint      = "192.168.50.201"
    talos_version = "v1.9.5"
  }

  nodes = {
    mars = {
      name            = "mars"
      ip              = "192.168.50.201"
      ssd_disk_id     = "nvme-SAMSUNG_MZVLB256HAHQ-000H7_S426NX0M109347"
      install_disk_id = "ata-KINGSTON_SA400S37480G_50026B7282642F76"
    }
    jupiter = {
      name            = "jupiter"
      ip              = "192.168.50.202"
      ssd_disk_id     = "nvme-CT2000P3PSSD8_2443E990D502"
      install_disk_id = "ata-KINGSTON_SA400S37240G_50026B7785719E80"
    },
    saturn = {
      name            = "saturn"
      ip              = "192.168.50.203"
      ssd_disk_id     = "nvme-CT2000P3PSSD8_2443E990D4E6"
      install_disk_id = "ata-KINGSTON_SA400S37240G_50026B778571955D"
    }
  }
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
