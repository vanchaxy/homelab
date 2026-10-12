locals {
  extensions = [
    "siderolabs/amdgpu",
    "siderolabs/amd-ucode",
    "siderolabs/intel-ucode",
    "siderolabs/iscsi-tools",
    "siderolabs/util-linux-tools",
  ]
  schematic    = join("", concat(["customization:\n    systemExtensions:\n        officialExtensions:\n"], [for e in local.extensions : "            - ${e}\n"]))
  schematic_id = sha256(local.schematic)
}

resource "terraform_data" "schematic" {
  triggers_replace = [local.schematic_id]

  provisioner "local-exec" {
    command = "${path.module}/register-schematic.sh"
    environment = {
      SCHEMATIC    = local.schematic
      SCHEMATIC_ID = local.schematic_id
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
