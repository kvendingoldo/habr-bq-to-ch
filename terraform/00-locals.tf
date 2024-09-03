locals {
  security_groups = {
    for k, v in var.security_groups : k => {

      ingress_rules = {
        for ing_k, ing_v in v["ingress_rules"] : ing_k => {
          protocol            = lookup(ing_v, "protocol", null)
          description         = lookup(ing_v, "description", null)
          labels              = lookup(ing_v, "labels", null)
          port                = lookup(ing_v, "port", null)
          from_port           = lookup(ing_v, "from_port", null)
          to_port             = lookup(ing_v, "to_port", null)
          security_group_name = lookup(ing_v, "security_group_name", null) != null ? format("%s-%s", var.common_name, ing_v["security_group_name"]) : null
          security_group_id   = lookup(ing_v, "security_group_id", null)
          predefined_target   = lookup(ing_v, "predefined_target", null)
          v4_cidr_blocks      = lookup(ing_v, "v4_cidr_blocks", null)
          v6_cidr_blocks      = lookup(ing_v, "v6_cidr_blocks", null)
        }
      }

      egress_rules = {
        for eg_k, eg_v in v["egress_rules"] : eg_k => {
          protocol            = lookup(eg_v, "protocol", null)
          description         = lookup(eg_v, "description", null)
          labels              = lookup(eg_v, "labels", null)
          port                = lookup(eg_v, "port", null)
          from_port           = lookup(eg_v, "from_port", null)
          to_port             = lookup(eg_v, "to_port", null)
          security_group_name = lookup(eg_v, "security_group_name", null) != null ? format("%s-%s", var.common_name, eg_v["security_group_name"]) : null
          security_group_id   = lookup(eg_v, "security_group_id", null)
          predefined_target   = lookup(eg_v, "predefined_target", null)
          v4_cidr_blocks      = lookup(eg_v, "v4_cidr_blocks", null)
          v6_cidr_blocks      = lookup(eg_v, "v6_cidr_blocks", null)
        }
      }
    }
  }

  zone2prvsubnet = {
    for item in module.network.private_subnets : item.zone => item.id
  }
  zone2pubsubnet = {
    for item in module.network.public_subnets : item.zone => item.id
  }

  clickhouse_clusters = {
    for k, v in var.clickhouse_clusters : k => {
      access              = v["access"]
      users               = v["users"]
      databases           = v["databases"]
      deletion_protection = v["deletion_protection"]

      clickhouse_disk_size          = v["disk_size"]
      clickhouse_disk_type_id       = v["disk_type_id"]
      clickhouse_resource_preset_id = v["resource_preset_id"]
      environment                   = v["environment"]
      clickhouse_version            = v["version"]
      description                   = v["description"]

      sql_user_management     = v["sql_user_management"]
      sql_database_management = v["sql_database_management"]

      shards = v["shards"]
      hosts  = [
        for obj in v["hosts"] : {
          type      = obj["type"]
          zone      = obj["zone"]
          subnet_id = lookup(obj, "assign_public_ip", false) ? local.zone2pubsubnet[obj["zone"]] : local.zone2prvsubnet[obj["zone"]]
          assign_public_ip = lookup(obj, "assign_public_ip", null)
        }
      ]

      cloud_storage            = v["cloud_storage"]
      copy_schema_on_new_hosts = v["copy_schema_on_new_hosts"]

      backup_window_start = v["backup_window_start"]

      maintenance_window_type = v["maintenance_window_type"]
      maintenance_window_hour = v["maintenance_window_hour"]
      maintenance_window_day  = v["maintenance_window_day"]
    }
  }
}