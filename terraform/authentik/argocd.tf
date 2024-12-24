data "infisical_secrets" "argocd-secret" {
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/argocd/argocd-secret/"
}

resource "authentik_provider_oauth2" "argocd" {
  name = "argocd"

  client_id     = "argocd"
  client_secret = data.infisical_secrets.argocd-secret.secrets["dex.authentik.clientSecret"].value

  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "http://localhost:8085/auth/callback",
    },
    {
      matching_mode = "strict",
      url           = "https://argocd.ivanchenko.io/api/dex/callback",
    },
  ]

  property_mappings = [
    data.authentik_property_mapping_provider_scope.scope-email.id,
    data.authentik_property_mapping_provider_scope.scope-profile.id,
    data.authentik_property_mapping_provider_scope.scope-openid.id,
  ]

  signing_key = data.authentik_certificate_key_pair.generated.id

  authorization_flow = data.authentik_flow.default-authorization-flow.id
  invalidation_flow  = data.authentik_flow.default-invalidation-flow.id
}

resource "authentik_application" "argocd" {
  name              = "argocd"
  slug              = "argocd"
  protocol_provider = authentik_provider_oauth2.argocd.id
  meta_launch_url   = "https://argocd.ivanchenko.io/auth/login"
}
