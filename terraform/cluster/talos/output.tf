output "machine_secrets" {
  value = talos_machine_secrets.this.machine_secrets
}

output "client_configuration" {
  value = talos_machine_secrets.this.client_configuration
}

output "talos_config" {
  value = data.talos_client_configuration.this.talos_config
}
