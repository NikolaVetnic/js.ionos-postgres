terraform {
  required_providers {
    ionoscloud = {
      source  = "ionos-cloud/ionoscloud"
      version = "6.4.5"
    }
  }
}

provider "ionoscloud" {
  token = var.ionos_token
}

# create VDC
resource "ionoscloud_datacenter" "enmeshed" {
  name        = "enmeshed-tf-postgresql"
  location    = var.location
  description = "deploy a postgresql database via terraform"
}

# create private lan
resource "ionoscloud_lan" "lan" {
  datacenter_id = ionoscloud_datacenter.enmeshed.id
  public        = false
  name          = "LAN"
}

resource "ionoscloud_lan" "uplink" {
  datacenter_id = ionoscloud_datacenter.enmeshed.id
  public        = true
  name          = "Uplink"
}


# create jumphost
resource "ionoscloud_server" "enmeshed" {
  name           = "server01"
  cores          = 2
  ram            = 2048
  datacenter_id  = ionoscloud_datacenter.enmeshed.id
  image_name     = var.default_image
  image_password = var.default_password
  ssh_keys       = [var.default_ssh_key_path]
  volume {
    size      = 10
    disk_type = "HDD"
    name = "hdd01"
  }
  nic {
    name                  = "nic_private"
    lan                   = ionoscloud_lan.lan.id
    dhcp                  = true
  }
}

locals {
 prefix                   = format("%s/%s", ionoscloud_server.enmeshed.nic[0].ips[0], "24")
 database_ip              = cidrhost(local.prefix, 9)
 database_ip_cidr         = format("%s/%s", local.database_ip, "24")
}

resource "ionoscloud_nic" "public_nic" {
  server_id       = ionoscloud_server.enmeshed.id
  datacenter_id   = ionoscloud_datacenter.enmeshed.id
  lan             = ionoscloud_lan.uplink.id
  name            = "nic_public"
  dhcp            = true
  firewall_active = false
}


# create Cluster
resource "ionoscloud_pg_cluster" "enmeshed" {
  postgres_version        = 15
  instances               = 1
  cores                   = 4
  ram                     = 2048
  storage_size            = 2048
  storage_type            = "HDD"
  connections   {
    datacenter_id         =  ionoscloud_datacenter.enmeshed.id 
    lan_id                =  ionoscloud_lan.lan.id 
    cidr                  =  local.database_ip_cidr
  }
  location                = var.location
  display_name            = "enmeshed_postgresql_cluster"
  credentials {
    username              = "enmeshed-user"
    password              = "EnmeshedPassw0rd"
  }
  synchronization_mode    = "ASYNCHRONOUS"
}

resource "ionoscloud_pg_database" "enmeshed" {
  cluster_id = ionoscloud_pg_cluster.enmeshed.id
  name = "enmeshed"
  owner = "enmeshed-user"
}

output "list_of_nics" {
  value = ionoscloud_nic.public_nic[*].ips
}

# connect from jumphost
#################
# sudo apt update
# sudo apt install -y postgresql-client   
# psql -U user01 -h IP_ADDRESS -d postgres
# psql -U user01 -h IP_ADDRESS -d stuff_db
#################
