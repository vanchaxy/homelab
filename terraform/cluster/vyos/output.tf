output "vps_router_config" {
  value = templatefile("${path.module}/vps-router.sh.tftpl", {
    laptop_public_ed25519_key = split(" ", var.laptop_public_ed25519)[1]
  })
}

output "home_router_config" {
  value = templatefile("${path.module}/home-router.sh.tftpl", {
    laptop_public_ed25519_key = split(" ", var.laptop_public_ed25519)[1]
  })
}
