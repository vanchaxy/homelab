resource "local_file" "machine_configs_mars" {
  content         = module.node-mars.machine_config.machine_configuration
  filename        = "../output/talos-machine-config-mars.yaml"
  file_permission = "0600"
}

resource "local_file" "machine_configs_jupiter" {
  content         = module.node-jupiter.machine_config.machine_configuration
  filename        = "../output/talos-machine-config-jupiter.yaml"
  file_permission = "0600"
}

resource "local_file" "machine_configs_saturn" {
  content         = module.node-saturn.machine_config.machine_configuration
  filename        = "../output/talos-machine-config-saturn.yaml"
  file_permission = "0600"
}

resource "local_file" "talos_config" {
  content         = module.talos.talos_config
  filename        = "../output/talos-config.yaml"
  file_permission = "0600"
}

resource "local_file" "vps_router_config" {
  content         = module.vyos.vps_router_config
  filename        = "../output/vps-router-config.sh"
  file_permission = "0600"
}

resource "local_file" "home_router_config" {
  content         = module.vyos.home_router_config
  filename        = "../output/home-router-config.sh"
  file_permission = "0600"
}

resource "terraform_data" "upgrade_router" {
  for_each         = local.routers
  triggers_replace = [local.vyos_version, var.vyos_apply_mode]

  provisioner "local-exec" {
    command = "${path.module}/vyos/upgrade.sh ${each.value} ${local.vyos_version}"
    environment = {
      VYOS_APPLY_MODE = var.vyos_apply_mode
    }
  }
}

resource "terraform_data" "apply_router" {
  for_each = {
    home = { content = local_file.home_router_config.content, filename = local_file.home_router_config.filename }
    vps  = { content = local_file.vps_router_config.content, filename = local_file.vps_router_config.filename }
  }

  triggers_replace = [
    sha256(each.value.content),
    sha256(jsonencode(module.vyos.bundles[each.key])),
    local.vyos_version,
    var.vyos_apply_mode,
  ]

  provisioner "local-exec" {
    command = "${path.module}/vyos/apply.sh ${local.routers[each.key]} ${each.value.filename}"
    environment = {
      VYOS_APPLY_MODE = var.vyos_apply_mode
      VYOS_BUNDLE     = jsonencode(module.vyos.bundles[each.key])
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
