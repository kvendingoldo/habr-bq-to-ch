#
# VM instances
#
module "vms" {
  for_each = var.vms

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-instance.git?ref=v1.0.0"

  name = format("%s-%s", var.common_name, each.key)

  zone       = each.value["zone"]
  subnet_id  = local.zone2prvsubnet[each.value["zone"]]
  enable_nat = each.value["enable_nat"]
  create_pip = each.value["create_pip"]
  security_group_ids = [
    module.security_groups[each.key].id
  ]

  hostname = each.key

  platform_id   = each.value["platform_id"]
  cores         = each.value["cores"]
  memory        = each.value["memory"]
  core_fraction = each.value["core_fraction"]
  preemptible   = each.value["preemptible"]

  image_family = each.value["image_family"]

  service_account_id = module.iam_accounts[each.key].id

  generate_ssh_key = each.value["generate_ssh_key"]
  ssh_user         = each.value["ssh_user"]
  user_data        = null

  boot_disk_initialize_params = each.value["boot_disk_initialize_params"]
  secondary_disks             = each.value["secondary_disks"]
}

#
# Secrets
#
module "vms_secrets" {
  for_each = var.vms

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-lockbox.git?ref=v1.0.0"

  name   = format("%s-%s", var.common_name, each.key)
  labels = {}

  entries = {
    "ssh-prv" : module.vms[each.key].ssh_key_prv
    "ssh-pub" : module.vms[each.key].ssh_key_pub
  }

  deletion_protection = false
}