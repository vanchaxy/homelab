resource "bitwarden_folder" "cloud_credentials" {
  name = "Kubernetes secrets"
}

resource "kubernetes_namespace" "bitwarden-ns" {
  metadata {
    name = "bitwarden"
  }
}

resource "kubernetes_secret" "bitwarden-secret" {
  metadata {
    name      = "bitwarden-cli"
    namespace = "bitwarden"
  }

  data = {
    "BW_HOST"     = "https://bitwarden.com"
    "BW_USERNAME" = var.bitwarden_email
    "BW_PASSWORD" = var.bitwarden_password
  }

  depends_on = [kubernetes_namespace.bitwarden-ns]
}
