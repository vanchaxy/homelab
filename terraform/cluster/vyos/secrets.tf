# Generated once and kept in the encrypted state. Existing values were imported,
# so nothing on the running routers changed. Rotate with `tofu apply -replace=...`.

resource "random_password" "vymanager_db" {
  length  = 32
  special = false
  lifecycle { ignore_changes = all }
}

resource "random_password" "vymanager_auth" {
  length  = 64
  special = false
  lifecycle { ignore_changes = all }
}

resource "random_password" "vymanager_ssh" {
  length  = 64
  special = false
  lifecycle { ignore_changes = all }
}

resource "random_password" "router_api_key" {
  length  = 64
  special = false
  lifecycle { ignore_changes = all }
}

resource "random_password" "adguard_admin" {
  length  = 24
  special = false
  lifecycle { ignore_changes = all }
}

resource "random_password" "vyos_login" {
  length  = 24
  special = false
}

resource "random_string" "vyos_login_salt" {
  length  = 16
  special = false
}

resource "wireguard_asymmetric_key" "home" {
  lifecycle { ignore_changes = all }
}

resource "wireguard_asymmetric_key" "vps" {
  lifecycle { ignore_changes = all }
}

resource "tailscale_tailnet_key" "router" {
  for_each            = toset(["home", "vps"])
  description         = "${each.key}-router container login"
  tags                = ["tag:router"]
  preauthorized       = true
  reusable            = false
  recreate_if_invalid = "always"
}
