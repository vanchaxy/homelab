resource "talos_image_factory_schematic" "this" {
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
}

data "talos_image_factory_urls" "this" {
  talos_version = var.cluster.talos_version
  schematic_id  = talos_image_factory_schematic.this.id
  platform      = "metal"
}

output "installer_url" {
  value = data.talos_image_factory_urls.this.urls.installer
}

output "iso_url" {
  value = data.talos_image_factory_urls.this.urls.iso
}
