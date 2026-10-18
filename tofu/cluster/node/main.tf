locals {
  # renovate: datasource=github-releases depName=cilium/cilium
  cilium_version = "v1.20.2"
  # renovate: datasource=docker depName=alpine/helm
  helm_version = "4.3.1"
}

data "talos_machine_configuration" "this" {
  cluster_name       = var.cluster.name
  cluster_endpoint   = "https://${var.cluster.endpoint}:6443"
  talos_version      = var.cluster.talos_version
  kubernetes_version = var.cluster.kubernetes_version
  machine_type       = var.node.machine_type
  machine_secrets    = var.machine_secrets
  config_patches = concat(
    [
      templatefile("${path.module}/config-patch.yaml.tftpl", {
        hostname           = var.node.name
        node_name          = var.node.name
        cluster_name       = var.cluster.name
        install_image      = var.talos_installer_url
        ssd_disk_id        = var.node.ssd_disk_id
        install_disk_id    = var.node.install_disk_id
        kubernetes_version = var.cluster.kubernetes_version
      })
    ],
    var.node.machine_type == "controlplane" ? [
      templatefile("${path.module}/controlplane-patch.yaml.tftpl", {
        cilium_values  = yamlencode(yamldecode(file("${path.module}/../../../k8s/system/cilium/values.yaml")).cilium)
        cilium_install = templatefile("${path.module}/manifests/cilium-install.yaml.tftpl", { cilium_version = trimprefix(local.cilium_version, "v"), helm_image = "docker.io/alpine/helm:${local.helm_version}" })
      })
    ] : [],
    var.extra_patches,
  )
}

locals {
  config_docs = [
    for d in split("\n---\n", data.talos_machine_configuration.this.machine_configuration) : yamldecode(d)
    if trimspace(d) != ""
  ]
  v1alpha1 = one([for d in local.config_docs : d if try(d.version, "") == "v1alpha1"])
  boot_config = {
    etcd       = try(local.v1alpha1.cluster.etcd, null)
    env        = try(local.v1alpha1.machine.env, null)
    kernel     = try(local.v1alpha1.machine.kernel, null)
    docs       = [for d in local.config_docs : d if contains(["EnvironmentConfig", "KernelModuleConfig", "SecurityProfileConfig"], try(d.kind, ""))]
    encryption = [for d in local.config_docs : { kind = d.kind, name = try(d.name, ""), encryption = d.encryption } if try(d.encryption, null) != null]
  }
}

resource "talos_machine_configuration_apply" "this" {
  node                        = var.node.name
  endpoint                    = var.node.ip
  client_configuration        = var.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this.machine_configuration
  apply_mode                  = "auto"

  depends_on = [var.after]
}
