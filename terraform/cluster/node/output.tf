output "machine_config" {
  value = data.talos_machine_configuration.this
}

output "talos_machine_configuration_apply_id" {
  value = talos_machine_configuration_apply.this.id
}
