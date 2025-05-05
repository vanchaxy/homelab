data "talos_image_factory_extensions_versions" "this" {
  talos_version = var.cluster.talos_version
  filters = {
    names = [
      "amdgpu",
      "amd-ucode",
      "iscsi-tools",
      "util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "this" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.this.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "this" {
  talos_version = var.cluster.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}

output "installer_url" {
  value = data.talos_image_factory_urls.this.urls.installer
}
