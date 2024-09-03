#
# yandex
#
variable "azs" {
  default = ["ru-central1-a", "ru-central1-b", "ru-central1-d"]
}

#
# naming
#
variable "common_name" {
  default = "habr-bg-to-ch"
}

#
# network
#
variable "subnets" {
  default = {
    public  = [["10.100.0.0/24"], ["10.101.0.0/24"], ["10.102.0.0/24"]]
    private = [["10.103.0.0/24"], ["10.104.0.0/24"], ["10.105.0.0/24"]]
  }
}

variable "security_groups" {
  default = {
    jumphost = {
      ingress_rules = {
        "ssh" = {
          protocol       = "tcp"
          port           = 22
          v4_cidr_blocks = ["0.0.0.0/0"]
          description    = "ssh"
        }
      }
      egress_rules = {
        "all" = {
          protocol       = "any"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }

    clickhouse-demo = {
      ingress_rules = {
        "self" = {
          protocol          = "any"
          from_port         = 0
          to_port           = 65535
          predefined_target = "self_security_group"
        }
        "8443_to_internet" = {
          protocol       = "tcp"
          port           = 8443
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
        "8123_to_internet" = {
          protocol       = "tcp"
          port           = 8123
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
        "9440_to_internet" = {
          protocol       = "tcp"
          port           = 9440
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
        "9000_to_internet" = {
          protocol       = "tcp"
          port           = 9000
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      }
      egress_rules = {
        "all" = {
          protocol       = "any"
          from_port      = 0
          to_port        = 65535
          v4_cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
}

#
# IAM
#
variable "iam" {
  default = {
    jumphost = {
      enabled                  = true
      folder_roles             = []
      cloud_roles              = []
      enable_static_access_key = false
      enable_api_key           = false
      enable_account_key       = false
    }

    clickhouse-demo = {
      enabled                  = true
      folder_roles             = []
      cloud_roles              = []
      enable_static_access_key = false
      enable_api_key           = false
      enable_account_key       = false
    }
  }
}

#
# Virtual Machines (VMs)
#
variable "vms" {
  default = {
    jumphost = {
      zone = "ru-central1-a"

      cloud_init = {
        initial_setup    = false
        cloud_init_debug = true
      }

      image_family = "ubuntu-2204-lts"

      platform_id   = "standard-v2"
      cores         = 2
      memory        = 2
      core_fraction = 100
      preemptible   = true

      create_pip       = true
      enable_nat       = true
      generate_ssh_key = true
      ssh_user         = "ubuntu"

      boot_disk_initialize_params = {
        size = 30
        type = "network-hdd"
      }

      secondary_disks = {}
    }
  }
}

#
# clickhouse
#
variable "clickhouse_clusters" {
  default = {
    "clickhouse-demo" = {
      access = {
        data_lens     = true
        metrika       = false
        web_sql       = true
        serverless    = false
        yandex_query  = false
        data_transfer = false
      }
      users               = []
      databases           = []
      deletion_protection = false

      disk_size          = 45
      disk_type_id       = "network-ssd"
      resource_preset_id = "s2.medium"
      environment        = "PRODUCTION"
      version            = "23.8"
      description        = "Demo for Habr: Data export from Google BigQuery"

      sql_user_management     = true
      sql_database_management = true

      zookeeper_disk_size          = null
      zookeeper_disk_type_id       = null
      zookeeper_resource_preset_id = null

      shards = [
        {
          name   = "master01"
          weight = 100
          resources = {
            resource_preset_id = "s2.micro"
            disk_size          = 5
            disk_type_id       = "network-ssd"
          }
        }
      ]
      hosts = [
        {
          shard_name       = "master01"
          type             = "CLICKHOUSE"
          zone             = "ru-central1-a"
          assign_public_ip = false
        },
        {
          shard_name       = "zk01"
          type             = "ZOOKEEPER"
          zone             = "ru-central1-a"
          assign_public_ip = false
        },
        {
          shard_name       = "zk02"
          type             = "ZOOKEEPER"
          zone             = "ru-central1-a"
          assign_public_ip = false
        },
        {
          shard_name       = "zk03"
          type             = "ZOOKEEPER"
          zone             = "ru-central1-a"
          assign_public_ip = false
        }
      ]
      cloud_storage = {
        enabled             = false
        move_factor         = 0
        data_cache_enabled  = true
        data_cache_max_size = 0
      }
      copy_schema_on_new_hosts = true

      backup_window_start = {
        hours   = "12"
        minutes = 00
      }

      maintenance_window_type = "WEEKLY"
      maintenance_window_hour = 1
      maintenance_window_day  = "SUN"
    }
  }
}
