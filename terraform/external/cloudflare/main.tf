data "infisical_secrets" "cloudflare-secret" {
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/cloudflare/"
}

data "cloudflare_zone" "zone" {
  filter = {
    name = "ivanchenko.io"
  }
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "homelab" {
  account_id    = var.cloudflare.account_id
  name          = "homelab"
  config_src    = "local"
  tunnel_secret = base64encode(data.infisical_secrets.cloudflare-secret.secrets["tunnel-secret"].value)
}

resource "cloudflare_dns_record" "tunnel" {
  zone_id = data.cloudflare_zone.zone.zone_id
  type    = "CNAME"
  name    = "homelab-tunnel.ivanchenko.io"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.homelab.id}.cfargotunnel.com"
  proxied = false
  ttl     = 1 # Auto
}

resource "infisical_secret" "cloudflare-tunnel-secret" {
  name = "credentialsjson"
  value = jsonencode({
    AccountTag   = var.cloudflare.account_id
    TunnelName   = cloudflare_zero_trust_tunnel_cloudflared.homelab.name
    TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.homelab.id
    TunnelSecret = base64encode(data.infisical_secrets.cloudflare-secret.secrets["tunnel-secret"].value)
  })
  env_slug     = var.infisical.env_slug
  workspace_id = var.infisical.workspace_id
  folder_path  = "/cloudflare/"
}
