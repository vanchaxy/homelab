locals {
  routers = {
    home-router = {
      routes = ["10.10.0.0/16", "0.0.0.0/0", "::/0"]
    }
    vps-router = {
      routes = []
    }
  }
}

resource "tailscale_acl" "this" {
  acl = file("${path.module}/policy.hujson")
}

data "tailscale_device" "router" {
  for_each = local.routers
  hostname = each.key
}

resource "tailscale_device_tags" "router" {
  for_each  = local.routers
  device_id = data.tailscale_device.router[each.key].node_id
  tags      = ["tag:router"]
}

resource "tailscale_device_key" "router" {
  for_each            = local.routers
  device_id           = data.tailscale_device.router[each.key].node_id
  key_expiry_disabled = true
}

resource "tailscale_device_subnet_routes" "router" {
  for_each  = { for k, v in local.routers : k => v if length(v.routes) > 0 }
  device_id = data.tailscale_device.router[each.key].node_id
  routes    = each.value.routes
}

import {
  to = tailscale_acl.this
  id = "acl"
}
