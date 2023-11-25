resource "hcloud_ssh_key" "default" {
  name       = var.ssh_key_name
  public_key = file(var.ssh_key_path)
}

resource "hcloud_server" "host" {
  for_each = var.hosts

  name        = each.key
  location    = var.location
  image       = var.image
  server_type = each.value.type
  ssh_keys    = [var.ssh_key_name]

  labels = { master : each.value.master }

  depends_on = [
    hcloud_ssh_key.default
  ]

}

resource "local_file" "inventory" {
  content = templatefile("templates/inventory.tmpl",
    {
      hosts     = var.hosts,
      hosts_ips = {
        for s in hcloud_server.host :
        s.name => s.ipv4_address
      },
    }
  )
  filename = "${var.ansible_inventory_path}/cloud.yml"
}
