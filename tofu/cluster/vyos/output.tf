output "vps_router_config" {
  value = templatefile("${path.module}/vps-router.sh.tftpl", {
    laptop_public_ed25519_key = split(" ", var.laptop_public_ed25519)[1]
    ci_public_ed25519_key     = split(" ", var.ci_public_ed25519)[1]
    home_router_wg_public_key = wireguard_asymmetric_key.home.public_key
  })
}

output "home_router_config" {
  value = templatefile("${path.module}/home-router.sh.tftpl", {
    laptop_public_ed25519_key = split(" ", var.laptop_public_ed25519)[1]
    ci_public_ed25519_key     = split(" ", var.ci_public_ed25519)[1]
    vps_wg_public_key         = wireguard_asymmetric_key.vps.public_key
  })
}

output "bundles" {
  value     = local.bundles
  sensitive = true
}

output "vyos_login_password" {
  value     = random_password.vyos_login.result
  sensitive = true
}

output "adguard_admin_password" {
  value     = random_password.adguard_admin.result
  sensitive = true
}
