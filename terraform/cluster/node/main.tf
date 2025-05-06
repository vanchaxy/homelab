data "talos_machine_configuration" "this" {
  cluster_name     = var.cluster.name
  cluster_endpoint = "https://${var.cluster.endpoint}:6443"
  talos_version    = var.cluster.talos_version
  machine_type     = "controlplane"
  machine_secrets  = var.machine_secrets
  config_patches = [
    templatefile("${path.module}/config-patch.yaml.tftpl", {
      hostname        = var.node.name
      node_name       = var.node.name
      cluster_name    = var.cluster.name
      install_image   = var.talos_installer_url
      cilium_values = yamlencode(yamldecode(file("${path.module}/../../../k8s/system/cilium/values.yaml")).cilium)
      cilium_install = file("${path.module}/manifests/cilium-install.yaml")
      ssd_disk_id     = var.node.ssd_disk_id
      usb_disk_id     = var.node.usb_disk_id
      install_disk_id = var.node.install_disk_id
    })
  ]
}

resource "talos_machine_configuration_apply" "this" {
  node                        = var.node.name
  endpoint                    = var.node.ip
  client_configuration        = var.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
}
