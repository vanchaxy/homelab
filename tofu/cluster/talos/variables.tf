variable "cluster" {
  type = object({
    name          = string
    endpoint      = string
    talos_version = string
  })
}

variable "nodes_ips" {
  type = list(string)
}

variable "worker_ips" {
  type        = list(string)
  default     = []
  description = "Workers added to the talosconfig's default nodes but not its endpoints"
}
