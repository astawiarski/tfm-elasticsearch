#VPC

module "vpc" {
  source       = "github.com/tuier/terraform-vpc-module"
  cluster_name = "${var.cluster_name}"
  region       = "${var.region}"

  #	azs_name = "${var.azs_name}"
  azs_count    = "${var.azs_count}"
  aws_key_name = "${var.key_name}"

  # dns
  fqdn           = "${var.cluster_name}.${var.fqdn}"
  route_zone_id  = "${var.route_zone_id}"
  network_number = "${var.network_number}"

  # extra user data
  user_data = "${var.bastion_extra_user_data}"
}
