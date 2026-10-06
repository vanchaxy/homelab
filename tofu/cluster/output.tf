output "files" {
  value = {
    "talos-machine-config-mars.yaml"    = module.node-mars.machine_config.machine_configuration
    "talos-machine-config-jupiter.yaml" = module.node-jupiter.machine_config.machine_configuration
    "talos-machine-config-saturn.yaml"  = module.node-saturn.machine_config.machine_configuration
    "talos-config.yaml"                 = module.talos.talos_config
    "kube-config.yaml"                  = module.talos.kubeconfig
    "vps-router-config.sh"              = module.vyos.vps_router_config
    "home-router-config.sh"             = module.vyos.home_router_config
  }
  sensitive = true
}

removed {
  from = local_file.machine_configs_mars
  lifecycle {
    destroy = false
  }
}

removed {
  from = local_file.machine_configs_jupiter
  lifecycle {
    destroy = false
  }
}

removed {
  from = local_file.machine_configs_saturn
  lifecycle {
    destroy = false
  }
}

removed {
  from = local_file.talos_config
  lifecycle {
    destroy = false
  }
}

removed {
  from = local_file.vps_router_config
  lifecycle {
    destroy = false
  }
}

removed {
  from = local_file.home_router_config
  lifecycle {
    destroy = false
  }
}

resource "terraform_data" "upgrade_router" {
  for_each         = local.routers
  triggers_replace = [local.vyos_version, var.apply_mode]

  provisioner "local-exec" {
    command = "${path.module}/vyos/upgrade.sh ${each.value} ${local.vyos_version}"
    environment = {
      APPLY_MODE = var.apply_mode
    }
  }
}

resource "terraform_data" "apply_router" {
  for_each = {
    home = module.vyos.home_router_config
    vps  = module.vyos.vps_router_config
  }

  triggers_replace = [
    sha256(each.value),
    sha256(jsonencode(module.vyos.bundles[each.key])),
    local.vyos_version,
    var.apply_mode,
  ]

  provisioner "local-exec" {
    command = "${path.module}/vyos/apply.sh ${local.routers[each.key]}"
    environment = {
      APPLY_MODE  = var.apply_mode
      VYOS_CONFIG = each.value
      VYOS_BUNDLE = jsonencode(module.vyos.bundles[each.key])
    }
  }

  depends_on = [terraform_data.upgrade_router]
}

output "vyos_login_password" {
  value     = module.vyos.vyos_login_password
  sensitive = true
}

output "adguard_admin_password" {
  value     = module.vyos.adguard_admin_password
  sensitive = true
}

resource "terraform_data" "apply_gl" {
  triggers_replace = [sha256(jsonencode(module.gl.files)), var.apply_mode]

  provisioner "local-exec" {
    command = "${path.module}/gl/apply.sh 10.10.10.2"
    environment = {
      APPLY_MODE = var.apply_mode
      GL_FILES   = jsonencode(module.gl.files)
    }
  }
}

output "wifi_keys" {
  value     = module.gl.wifi_keys
  sensitive = true
}

data "external" "running_versions" {
  program = concat(["${path.module}/talos/versions.sh"], [for k, v in local.nodes : v.ip])
}

locals {
  wanted_versions = {
    talos      = local.cluster.talos_version
    kubernetes = local.cluster.kubernetes_version
  }
  version_jumps = {
    for k, to in local.wanted_versions : k => {
      from  = data.external.running_versions.result[k]
      to    = to
      major = tonumber(regex("^v?(\\d+)", to)[0]) - tonumber(regex("^v?(\\d+)", data.external.running_versions.result[k])[0])
      minor = tonumber(regex("^v?\\d+\\.(\\d+)", to)[0]) - tonumber(regex("^v?\\d+\\.(\\d+)", data.external.running_versions.result[k])[0])
    }
  }
}

resource "terraform_data" "upgrade_talos" {
  triggers_replace = [local.cluster.talos_version, module.talos.installer_url, var.apply_mode]

  lifecycle {
    precondition {
      condition     = local.version_jumps.talos.major == 0 && local.version_jumps.talos.minor >= 0 && local.version_jumps.talos.minor <= 1
      error_message = "Talos ${local.version_jumps.talos.from} -> ${local.version_jumps.talos.to}: upgrade one minor version at a time, never down."
    }
  }

  provisioner "local-exec" {
    command = join(" ", concat(
      ["${path.module}/talos/upgrade-talos.sh", local.cluster.talos_version, module.talos.installer_url],
      [for name in ["mars", "jupiter", "saturn"] : "${name}=${local.nodes[name].ip}"],
    ))
    environment = {
      APPLY_MODE = var.apply_mode
    }
  }
}

resource "terraform_data" "upgrade_k8s" {
  triggers_replace = [local.cluster.kubernetes_version, var.apply_mode]

  lifecycle {
    precondition {
      condition     = local.version_jumps.kubernetes.major == 0 && local.version_jumps.kubernetes.minor >= 0 && local.version_jumps.kubernetes.minor <= 1
      error_message = "Kubernetes ${local.version_jumps.kubernetes.from} -> ${local.version_jumps.kubernetes.to}: upgrade one minor version at a time, never down."
    }
  }

  provisioner "local-exec" {
    command = "${path.module}/talos/upgrade-k8s.sh ${local.cluster.kubernetes_version} ${local.nodes.mars.ip}"
    environment = {
      APPLY_MODE = var.apply_mode
    }
  }

  depends_on = [terraform_data.upgrade_talos]
}
