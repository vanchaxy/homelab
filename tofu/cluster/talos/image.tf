locals {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = [
            "siderolabs/amdgpu",
            "siderolabs/amd-ucode",
            "siderolabs/intel-ucode",
            "siderolabs/iscsi-tools",
            "siderolabs/util-linux-tools",
          ]
        }
      }
    }
  )
  schematic_id = jsondecode(data.http.schematic.response_body).id
}

data "http" "schematic" {
  url                = "https://factory.talos.dev/schematics"
  method             = "POST"
  request_body       = local.schematic
  request_timeout_ms = 30000

  retry {
    attempts     = 5
    min_delay_ms = 2000
    max_delay_ms = 30000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 || self.status_code == 201
      error_message = "factory.talos.dev returned ${self.status_code} for the schematic: ${self.response_body}"
    }
  }
}

removed {
  from = talos_image_factory_schematic.this
  lifecycle {
    destroy = false
  }
}

output "installer_url" {
  value = "factory.talos.dev/metal-installer/${local.schematic_id}:${var.cluster.talos_version}"
}

output "iso_url" {
  value = "https://factory.talos.dev/image/${local.schematic_id}/${var.cluster.talos_version}/metal-amd64.iso"
}
