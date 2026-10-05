locals {
  ssids = toset(["Home", "Home-Work", "Home-IoT", "Home-Guest"])
}

# Generated once and kept in the encrypted state; the existing passphrases
# were imported. Rotate one with `tofu apply -replace='module.gl.random_password.wifi["Home"]'`.
resource "random_password" "wifi" {
  for_each = local.ssids
  length   = 20
  special  = false
  lifecycle { ignore_changes = all }
}

locals {
  wifi_keys = { for s in local.ssids : s => random_password.wifi[s].result }

  files = merge(
    {
      for name in ["network", "wireless", "dhcp", "system", "firewall"] :
      "/etc/config/${name}" => templatefile("${path.module}/config/${name}.tftpl", { wifi_keys = local.wifi_keys })
    },
    { "/etc/dropbear/authorized_keys" = join("", [for k in var.authorized_keys : "${trimspace(k)}\n"]) },
  )
}
