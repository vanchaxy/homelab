locals {
  vymanager_db_url = "postgresql://vymanager:${random_password.vymanager_db.result}@172.31.255.2:5432/vymanager"

  login_files = {
    "/config/auth/login-password.vyos" = { content = random_password.vyos_login.result, mode = "600" }
    "/config/auth/login-salt.vyos"     = { content = random_string.vyos_login_salt.result, mode = "600" }
  }

  bundles = {
    home = merge(local.login_files, {
      "/config/auth/wg-pub.priv"                                   = { content = wireguard_asymmetric_key.home.private_key, mode = "600" }
      "/config/auth/wg-pub.key"                                    = { content = wireguard_asymmetric_key.home.public_key, mode = "600" }
      "/config/auth/tailscale-authkey"                             = { content = tailscale_tailnet_key.router["home"].key, mode = "600" }
      "/config/auth/https-api-key.vymanager"                       = { content = random_password.router_api_key.result, mode = "600" }
      "/config/auth/vymanager-backend.VYMANAGER_APPLIANCE_API_KEY" = { content = random_password.router_api_key.result, mode = "600" }
      "/config/auth/vymanager-backend.BETTER_AUTH_SECRET"          = { content = random_password.vymanager_auth.result, mode = "600" }
      "/config/auth/vymanager-frontend.BETTER_AUTH_SECRET"         = { content = random_password.vymanager_auth.result, mode = "600" }
      "/config/auth/vymanager-backend.SSH_ENCRYPTION_KEY"          = { content = random_password.vymanager_ssh.result, mode = "600" }
      "/config/auth/vymanager-postgres.POSTGRES_PASSWORD"          = { content = random_password.vymanager_db.result, mode = "600" }
      "/config/auth/vymanager-backend.DATABASE_URL"                = { content = local.vymanager_db_url, mode = "600" }
      "/config/auth/vymanager-frontend.DATABASE_URL"               = { content = local.vymanager_db_url, mode = "600" }
      "/config/containers/mdns-log/run.sh"                         = { content = file("${path.module}/mdns-log.sh"), mode = "755" }
      "/config/containers/adguard/conf/AdGuardHome.yaml" = {
        content   = templatefile("${path.module}/adguard-home.yaml.tftpl", { admin_password_bcrypt = random_password.adguard_admin.bcrypt_hash })
        mode      = "600"
        seed_only = true
      }
    })
    vps = merge(local.login_files, {
      "/config/auth/wg-pub.priv"       = { content = wireguard_asymmetric_key.vps.private_key, mode = "600" }
      "/config/auth/wg-pub.key"        = { content = wireguard_asymmetric_key.vps.public_key, mode = "600" }
      "/config/auth/tailscale-authkey" = { content = tailscale_tailnet_key.router["vps"].key, mode = "600" }
    })
  }
}
