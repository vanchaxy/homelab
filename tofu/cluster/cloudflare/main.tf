data "cloudflare_zone" "vnchx" {
  filter = {
    name = "vnchx.com"
  }
}

resource "cloudflare_zone_setting" "vnchx_ssl" {
  zone_id    = data.cloudflare_zone.vnchx.id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_ruleset" "vnchx_cache" {
  zone_id = data.cloudflare_zone.vnchx.id
  name    = "default"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules = [{
    description = "Electric shapes"
    expression  = "(http.host eq \"electric.vnchx.com\" and starts_with(http.request.uri.path, \"/v1/shape\"))"
    action      = "set_cache_settings"
    action_parameters = {
      cache = true
      edge_ttl = {
        mode = "respect_origin"
      }
      browser_ttl = {
        mode = "respect_origin"
      }
    }
  }]
}
