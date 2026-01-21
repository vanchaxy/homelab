output "wg_public_key" {
  value = wireguard_asymmetric_key.vyos.public_key
}

output "vyos_config" {
  value = templatefile("${path.module}/config.sh.tftpl", {
    wg_private_key        = wireguard_asymmetric_key.vyos.private_key
    forward_ip            = var.forward_ip
    nodes                 = var.nodes
    laptop_public_ed25519 = var.laptop_public_ed25519
  })
}

