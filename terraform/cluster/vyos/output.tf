output "vyos_config" {
  value = templatefile("${path.module}/config.sh.tftpl", {
    forward_ip             = var.forward_ip
    vps_tailnet_ip         = var.vps_tailnet_ip
    home_router_tailnet_ip = var.home_router_tailnet_ip
    laptop_public_ed25519  = var.laptop_public_ed25519
  })
}
