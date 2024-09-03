module "network" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-vpc.git?ref=v1.7.0"

  blank_name = var.common_name

  azs = var.azs

  create_nat_gateway = true

  public_subnets  = var.subnets["public"]
  private_subnets = var.subnets["private"]
}

module "security_groups" {
  for_each = local.security_groups

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-security-group.git?ref=v1.0.0"

  blank_name = format("%s-%s", var.common_name, each.key)

  vpc_id = module.network.vpc_id

  ingress_rules = each.value["ingress_rules"]
  egress_rules  = each.value["egress_rules"]

  depends_on = [
    module.network
  ]
}

module "iam_accounts" {
  for_each = {
    for k, v in var.iam : k => v if v["enabled"]
  }

  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-iam.git//modules/iam-account?ref=v1.0.0"

  name = format("%s-%s", var.common_name, each.key)

  folder_roles = each.value["folder_roles"]
  cloud_roles  = each.value["cloud_roles"]

  enable_static_access_key = each.value["enable_static_access_key"]
  enable_api_key           = each.value["enable_api_key"]
  enable_account_key       = each.value["enable_account_key"]
}
