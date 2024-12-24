data "infisical_secrets" "immich-secret" {
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/immich/authentik/"
}

resource "authentik_provider_oauth2" "immich" {
  name = "immich"

  client_id     = "immich"
  client_secret = data.infisical_secrets.immich-secret.secrets["clientSecret"].value

  allowed_redirect_uris = [
    {
      matching_mode = "strict",
      url           = "app.immich:///oauth-callback",
    },
    {
      matching_mode = "strict",
      url           = "https://immich.ivanchenko.io/auth/login",
    },
        {
      matching_mode = "strict",
      url           = "https://immich.ivanchenko.io/user-settings",
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

resource "authentik_application" "immich" {
  name              = "immich"
  slug              = "immich"
  protocol_provider = authentik_provider_oauth2.immich.id
  meta_launch_url   = "https://immich.ivanchenko.io/auth/login"
}
