output "vyos_config" {
  value = templatefile("${path.module}/config.sh.tftpl", {
    forward_ip                = var.forward_ip
    home_router_wg_public_key = var.home_router_wg_public_key
    laptop_public_ed25519     = var.laptop_public_ed25519
  })
}

output "home_router_config" {
  value = templatefile("${path.module}/home-router.sh.tftpl", {
    laptop_public_ed25519_key = split(" ", var.laptop_public_ed25519)[1]
  })
}
