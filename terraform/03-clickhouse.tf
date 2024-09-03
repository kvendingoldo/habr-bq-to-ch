module "clickhouse" {
  for_each = local.clickhouse_clusters

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-mdb-clickhouse.git?ref=main"

  name = format("%s-%s", var.common_name, each.key)
  labels = {}

  network_id = module.network.vpc_id
  security_group_ids = [module.security_groups[each.key].id]

  access              = each.value["access"]
  users               = each.value["users"]
  databases           = each.value["databases"]
  deletion_protection = each.value["deletion_protection"]

  clickhouse_disk_size          = each.value["clickhouse_disk_size"]
  clickhouse_disk_type_id       = each.value["clickhouse_disk_type_id"]
  clickhouse_resource_preset_id = each.value["clickhouse_resource_preset_id"]
  environment                   = each.value["environment"]
  clickhouse_version            = each.value["clickhouse_version"]
  description                   = each.value["description"]

  sql_user_management     = each.value["sql_user_management"]
  sql_database_management = each.value["sql_database_management"]
  admin_password          = each.value["sql_user_management"] ? random_password.clickhouse_admin_password[each.key].result: null

  shards                   = each.value["shards"]
  hosts                    = each.value["hosts"]
  cloud_storage            = each.value["cloud_storage"]
  copy_schema_on_new_hosts = each.value["copy_schema_on_new_hosts"]

  backup_window_start = each.value["backup_window_start"]
  maintenance_window = {
    type = each.value["maintenance_window_type"]
    day  = each.value["maintenance_window_day"]
    hour = each.value["maintenance_window_hour"]
  }
  depends_on = [module.iam_accounts, module.network]
}


resource "random_password" "clickhouse_admin_password" {
  for_each = {
    for k, v in local.clickhouse_clusters : k => v if v["sql_user_management"]
  }

  length           = 8
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

module "clickhouse_secrets" {
  for_each = {
    for k, v in local.clickhouse_clusters : k => v if v["sql_user_management"]
  }

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-lockbox.git?ref=v1.0.0"

  name = format("%s-clickhouse-%s", var.common_name, each.key)
  labels = {}

  entries =  {
      "admin-password" : random_password.clickhouse_admin_password[each.key].result
    }

  deletion_protection = false
}