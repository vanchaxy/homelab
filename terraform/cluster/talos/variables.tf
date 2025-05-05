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
