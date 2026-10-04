removed {
  from = cloudflare_tunnel.homelab

  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_record.tunnel

  lifecycle {
    destroy = false
  }
}

import {
  to = cloudflare_zero_trust_tunnel_cloudflared.homelab
  id = "4b40d53fa456cffe52c2dc74c93fea79/191745f4-45c4-4697-b5f9-bc135e5b7465"
}

import {
  to = cloudflare_dns_record.tunnel
  id = "5628ef46a46d36be473478c3f0176264/a38998d739757287df05fb164836fd2f"
}
