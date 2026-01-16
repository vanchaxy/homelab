locals {
  cluster = {
    name               = "talos-homelab"
    endpoint           = "192.168.50.201"
    talos_version      = "v1.11.3"
    kubernetes_version = "v1.34.2"
  }

  nodes = {
    mars = {
      name             = "mars"
      ip               = "192.168.50.201"
      ssd_disk_id      = "nvme-SAMSUNG_MZVLB256HAHQ-000H7_S426NX0M109347"
      install_disk_id  = "ata-KINGSTON_SA400S37480G_50026B7282642F76"
      wg_ip            = "10.100.0.2"
      vps_wg_ip        = "10.100.0.1"
      vps_wg_interface = "wg0"
      vps_wg_port      = "51820"
    }
    jupiter = {
      name             = "jupiter"
      ip               = "192.168.50.202"
      ssd_disk_id      = "nvme-CT2000P3PSSD8_2443E990D502"
      install_disk_id  = "ata-KINGSTON_SA400S37240G_50026B7785719E80"
      wg_ip            = "10.100.1.2"
      vps_wg_ip        = "10.100.1.1"
      vps_wg_interface = "wg1"
      vps_wg_port      = "51821"
    },
    saturn = {
      name             = "saturn"
      ip               = "192.168.50.203"
      ssd_disk_id      = "nvme-CT2000P3PSSD8_2443E990D4E6"
      install_disk_id  = "ata-KINGSTON_SA400S37240G_50026B778571955D"
      wg_ip            = "10.100.2.2"
      vps_wg_ip        = "10.100.2.1"
      vps_wg_interface = "wg2"
      vps_wg_port      = "51822"
    }
  }

  vps_main_ip    = "202.61.245.36"
  vps_forward_ip = "46.38.230.69"
}

module "vyos" {
  source = "./vyos"

  nodes = {
    mars    = { node = local.nodes.mars, pubkey = module.node-mars.wg_public_key },
    jupiter = { node = local.nodes.jupiter, pubkey = module.node-jupiter.wg_public_key },
    saturn  = { node = local.nodes.saturn, pubkey = module.node-saturn.wg_public_key }
  }
  laptop_public_ed25519 = var.laptop_public_ed25519
  forward_ip            = local.vps_forward_ip
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

  vps_wg = {
    ip         = local.vps_main_ip
    public_key = module.vyos.wg_public_key
  }

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-jupiter" {
  source = "./node"

  cluster = local.cluster
  node    = local.nodes.jupiter

  vps_wg = {
    ip         = local.vps_main_ip
    public_key = module.vyos.wg_public_key
  }

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}

module "node-saturn" {
  source = "./node"

  cluster = local.cluster
  node    = local.nodes.saturn

  vps_wg = {
    ip         = local.vps_main_ip
    public_key = module.vyos.wg_public_key
  }

  talos_installer_url = module.talos.installer_url

  machine_secrets      = module.talos.machine_secrets
  client_configuration = module.talos.client_configuration
}
