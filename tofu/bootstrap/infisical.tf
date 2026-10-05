resource "kubectl_manifest" "infisical-ns" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: infisical
YAML
}

resource "kubectl_manifest" "infisical-secret" {
  yaml_body = <<YAML
apiVersion: v1
kind: Secret
data:
  clientId: ${base64encode(var.infisical.client_id)}
  clientSecret: ${base64encode(var.infisical.client_secret)}
metadata:
  name: universal-auth-credentials
  namespace: infisical
YAML
}
