terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "0.12.0"
    }
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.4.1"
    }
  }
}
