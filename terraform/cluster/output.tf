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
