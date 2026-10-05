variable "authorized_keys" {
  type        = list(string)
  description = "SSH public keys allowed to log in as root (dropbear)"
}
