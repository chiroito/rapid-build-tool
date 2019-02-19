data "oci_identity_regions" "regions" {
  filter {
    name = "key"
    values = [
      "${var.env["runtime_region_shortname"]}"]
  }
}

#output "region" {
#  value = "${lookup(data.oci_identity_regions.regions.regions[0], "name")}"
#}

locals {
  availability_domain_prefix = {
    "IAD" = "TGjA:US-ASHBURN-AD-"
    "PHX" = "TGjA:PHX-AD-"
  }
}

#data "oci_core_private_ips" "test_private_ips_by_subnet" {
#Optional
#  subnet_id = "${oci_core_subnet.app_subnet.}"
#}



#locals{
#  count = "${length(data.oci_core_private_ips.private_ips_in_app_subnet.private_ips)}"
#  ips = "${list(ips, lookup(data.oci_core_private_ips.private_ips_in_app_subnet.private_ips[count.index],"ip_address"))}"
#}

