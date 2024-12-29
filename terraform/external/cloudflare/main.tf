data "infisical_secrets" "cloudflare-secret" {
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/cloudflare/"
}

data "cloudflare_zone" "zone" {
  name = "ivanchenko.io"
}

resource "cloudflare_tunnel" "homelab" {
  account_id = var.cloudflare.account_id
  name       = "homelab"
  secret = base64encode(data.infisical_secrets.cloudflare-secret.secrets["tunnel-secret"].value)
}

resource "cloudflare_record" "tunnel" {
  zone_id = data.cloudflare_zone.zone.id
  type    = "CNAME"
  name    = "homelab-tunnel"
  value   = "${cloudflare_tunnel.homelab.id}.cfargotunnel.com"
  proxied = false
  ttl     = 1 # Auto
}

resource "infisical_secret" "cloudflare-tunnel-secret" {
  name = "credentialsjson"
  value = jsonencode({
    AccountTag = var.cloudflare.account_id
    TunnelName = cloudflare_tunnel.homelab.name
    TunnelID   = cloudflare_tunnel.homelab.id
    TunnelSecret = base64encode(data.infisical_secrets.cloudflare-secret.secrets["tunnel-secret"].value)
  })
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/cloudflare/"
}
