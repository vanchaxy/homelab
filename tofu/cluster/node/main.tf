locals {
  # renovate: datasource=github-releases depName=cilium/cilium
  cilium_version = "v1.18.6"
  # renovate: datasource=docker depName=quay.io/cilium/cilium-cli
  cilium_cli_version = "v0.20.1"
}

data "talos_machine_configuration" "this" {
  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
  machine_type       = "controlplane"
  machine_secrets    = var.machine_secrets
  config_patches = [
    templatefile("${path.module}/config-patch.yaml.tftpl", {
      hostname        = var.node.name
      node_name       = var.node.name
      cluster_name    = var.cluster.name
      install_image   = var.talos_installer_url
      cilium_values   = yamlencode(yamldecode(file("${path.module}/../../../k8s/system/cilium/values.yaml")).cilium)
      cilium_install  = templatefile("${path.module}/manifests/cilium-install.yaml.tftpl", { cilium_version = local.cilium_version, cilium_cli_image = "quay.io/cilium/cilium-cli:${local.cilium_cli_version}" })
      ssd_disk_id     = var.node.ssd_disk_id
      install_disk_id = var.node.install_disk_id
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  node                        = var.node.name
  endpoint                    = "${var.node.ip}${substr(var.after, 0, 0)}"
  client_configuration        = var.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  apply_mode                  = "staged_if_needing_reboot"
}
