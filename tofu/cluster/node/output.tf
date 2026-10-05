output "machine_config" {
  value = data.talos_machine_configuration.this
}

output "talos_machine_configuration_apply_id" {
  value = talos_machine_configuration_apply.this.id
}

output "resolved_apply_mode" {
  value = talos_machine_configuration_apply.this.resolved_apply_mode
}

output "machine_configuration_sha" {
  value     = sha256(talos_machine_configuration_apply.this.machine_configuration_input)
  sensitive = true
}
