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

data "talos_image_factory_extensions_versions" "nas" {
  talos_version = var.cluster.talos_version
  filters = {
    names = [
      "intel-ucode",
      "iscsi-tools",
      "util-linux-tools",
    ]
  }
}

resource "talos_image_factory_schematic" "nas" {
  schematic = yamlencode(
    {
      customization = {
        extraKernelArgs = [
          "intel_iommu=on",
          "iommu=pt",
        ]
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.nas.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "nas" {
  talos_version = var.cluster.talos_version
  schematic_id  = talos_image_factory_schematic.nas.id
  platform      = "metal"
}

output "nas_installer_url" {
  value = data.talos_image_factory_urls.nas.urls.installer
}

output "nas_iso_url" {
  value = data.talos_image_factory_urls.nas.urls.iso
}
