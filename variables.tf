variable "ionos_token" {
  sensitive = true
}

variable "location" {
  default = "de/txl"
}

variable "default_password" {
  default = "DefaultEnmeshedPassw0rd"
}

variable "default_ssh_key_path" {
  default = "/Users/nikolavetnic/.ssh/id_ed25519.pub"
}

variable "default_image" {
  default = "ubuntu:latest"
}
