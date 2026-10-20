resource "talos_machine_secrets" "this" {
  talos_version = var.cluster.talos_version

  lifecycle {
    ignore_changes = [talos_version]
  }
}

data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration
  nodes                = concat(var.nodes_ips, var.worker_ips)
  endpoints            = var.nodes_ips
}

resource "talos_cluster_kubeconfig" "this" {
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = var.cluster.endpoint
}
