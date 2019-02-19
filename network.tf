# 仮想クラウドネットワーク
resource "oci_core_vcn" "primary_vcn" {
  cidr_block = "${local.vcn_cidr}"
  compartment_id = "${var.env["primary_compartment_ocid"]}"
  display_name = "${var.env["primary_vcn_name"]}"
  dns_label = "${var.env["primary_dns_label"]}"
}
# https://www.terraform.io/docs/providers/oci/r/core_vcn.html

# Internet Gateway
resource "oci_core_internet_gateway" "primary_ig" {
  display_name = "ig-tf"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"

}
# see: https://www.terraform.io/docs/providers/oci/r/core_internet_gateway.html

# Default Route Table
resource "oci_core_default_route_table" "primary_default_route_table" {
  manage_default_resource_id = "${oci_core_vcn.primary_vcn.default_route_table_id}"

  route_rules = {
    destination = "${local.internet_cidr}"
    destination_type = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.primary_ig.id}"
  }
}
# https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html

# Default DHCP Option
resource "oci_core_default_dhcp_options" "primary_default_dhcp_options" {
  manage_default_resource_id = "${oci_core_vcn.primary_vcn.default_dhcp_options_id}"

  options = [
    {
      type = "DomainNameServer"
      server_type = "VcnLocalPlusInternet"
    },
    {
      type = "SearchDomain"
      search_domain_names = [
        "${var.env["domain_name"]}"]
    }]
}
# https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html

# Defautl Security List
resource "oci_core_default_security_list" "primary_default_security_list" {
  manage_default_resource_id = "${oci_core_vcn.primary_vcn.default_security_list_id}"

  ingress_security_rules = [
    {
      protocol = "${local.tcp}"
      source = "${local.internet_cidr}"
      tcp_options = {
        "min" = 22
        "max" = 22
      }
    },
    {
      protocol = "${local.icmp}"
      source = "${local.vcn_cidr}"
      stateless = true
      icmp_options = {
        "type" = 3
        "code" = 4
      }
    }]

  egress_security_rules = [
    {
      protocol = "${local.tcp}"
      destination = "${local.internet_cidr}"
      tcp_options = {
        "min" = 80
        "max" = 80
      }
    },
    {
      protocol = "${local.tcp}"
      destination = "${local.internet_cidr}"
      tcp_options = {
        "min" = 443
        "max" = 443
      }
    }]
}
# https://www.terraform.io/docs/providers/oci/guides/managing_default_resources.html

# Security List
// https://www.terraform.io/docs/providers/oci/r/core_security_list.html

# Load Balancer の Security List
resource "oci_core_security_list" "sl_for_lb" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for load balancer"

  ingress_security_rules = [
    {
      protocol = "${local.tcp}"
      source = "${local.internet_cidr}"
      tcp_options = {
        "min" = "${local.em_express_port}"
        "max" = "${local.em_express_port}"
      }
    },
    {
      protocol = "${local.tcp}"
      source = "${local.internet_cidr}"
      tcp_options = {
        "min" = "${local.admin_https_port}"
        "max" = "${local.admin_https_port}"
      }
    },
    {
      protocol = "${local.tcp}"
      source = "${local.internet_cidr}"
      tcp_options = {
        "min" = "${local.app_https_port}"
        "max" = "${local.app_https_port}"
      }
    }]

  egress_security_rules = []

}

# Application Server (WebLogic Server)の Security List
resource "oci_core_security_list" "sl_for_app_server" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for Application Server"

  ingress_security_rules = [
    {
      protocol = "${local.tcp}"
      source = "${local.app_cidr}"
    },
    {
      protocol = "${local.udp}"
      source = "${local.app_cidr}"
    }]

  egress_security_rules = [
    {
      protocol = "${local.tcp}"
      destination = "${local.app_cidr}"
    },
    {
      protocol = "${local.udp}"
      destination = "${local.app_cidr}"
    },
    {
      protocol = "${local.tcp}"
      destination = "${local.app_db_cidr}"
      tcp_options = {
        "min" = "${local.db_connection_port}"
        "max" = "${local.db_connection_port}"
      }
    },
    {
      protocol = "${local.tcp}"
      destination = "${local.repo_db_cidr}"
      tcp_options = {
        "min" = "${local.db_connection_port}"
        "max" = "${local.db_connection_port}"
      }
    }]

}

# Database の Security List
resource "oci_core_security_list" "sl_for_db" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for db server"

  ingress_security_rules = [
    {
      protocol = "${local.tcp}"
      source = "${local.app_cidr}"
      tcp_options = {
        "min" = "${local.db_connection_port}"
        "max" = "${local.db_connection_port}"
      }
    }
  ]
}

# Application Server が管理ツール(WebLogic Admin Console)への接続を受付ける Security List
resource "oci_core_security_list" "sl_for_accept_wls_admin" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accepting weblogic admin tools"
  ingress_security_rules = [
    "${local.weblogic_admin_rule[local.weblogic_admin_mode]}"]

}

# Application Server が Application への接続を受付ける Security List
resource "oci_core_security_list" "sl_for_accept_app" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accepting application"
  ingress_security_rules = "${local.application_rule[local.app_mode]}"

}

# Application 用のデータベースが管理ツール(Enterprise Manager)への接続を受付ける Security List
resource "oci_core_security_list" "sl_for_accept_em" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accepting enterprise manager"
  ingress_security_rules = "${local.em_rule[local.em_mode]}"

}

# Application へアクセスするための Security List
resource "oci_core_security_list" "sl_for_access_app" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accessing app"

  egress_security_rules = [
    {
      protocol = "${local.tcp}"
      destination = "${local.app_cidr}"
      tcp_options = {
        "min" = "${local.app_https_port}"
        "max" = "${local.app_https_port}"
      }
    },
    {
      protocol = "${local.tcp}"
      destination = "${local.app_cidr}"
      tcp_options = {
        "min" = "${local.app_http_port}"
        "max" = "${local.app_http_port}"
      }
    }
  ]

}

# WebLogic Server の管理ツール(WebLogic Admin Console)へアクセスするための Security List
resource "oci_core_security_list" "sl_for_access_wls_admin" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accessing Weblogic Admin Console"

  egress_security_rules = [
    {
      protocol = "${local.tcp}"
      destination = "${local.app_cidr}"
      tcp_options = {
        "min" = "${local.admin_https_port}"
        "max" = "${local.admin_https_port}"
      }
    },
    {
      protocol = "${local.tcp}"
      destination = "${local.app_cidr}"
      tcp_options = {
        "min" = "${local.admin_http_port}"
        "max" = "${local.admin_http_port}"
      }
    }
  ]

}

# Application が使う Database の管理ツール(Enterprise Manager Express)へアクセスするための Security List
resource "oci_core_security_list" "sl_for_access_em" {

  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  display_name = "security list for accessing Enterprise Manager"

  egress_security_rules = [
    {
      protocol = "${local.tcp}"
      destination = "${local.app_db_cidr}"
      tcp_options = {
        "min" = "${local.em_express_port}"
        "max" = "${local.em_express_port}"
      }
    }
  ]

}

# Repository Database 用のサブネット
resource "oci_core_subnet" "repo_subnet" {
  depends_on = [
    "oci_core_default_route_table.primary_default_route_table",
    "oci_core_default_dhcp_options.primary_default_dhcp_options",
    "oci_core_default_security_list.primary_default_security_list"]
  display_name = "repository db subnet"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  availability_domain = "${local.availability_domain}"
  dns_label = "repo"
  cidr_block = "${local.repo_db_cidr}"
  security_list_ids = [
    "${oci_core_security_list.sl_for_db.id}",
    "${oci_core_vcn.primary_vcn.default_security_list_id}"]

}

# Load Balancer (Primary)用のサブネット
resource "oci_core_subnet" "lb_subnet_primary" {
  count = "${local.is_need_lb ? 1 : 0 }"
  display_name = "LB primary subnet"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  availability_domain = "${local.availability_domain}"
  dns_label = "lbp"
  cidr_block = "${local.lb_primary_cidr}"
  security_list_ids = [
    "${compact(list(local.em_mode == "LB" ? oci_core_security_list.sl_for_access_em.id : "",
    local.weblogic_admin_mode == "LB" ? oci_core_security_list.sl_for_access_wls_admin.id : "",
    local.app_mode == "LB" ? oci_core_security_list.sl_for_access_app.id : "",
    oci_core_security_list.sl_for_lb.id))}"]

}

# Load Balancer (Backup)用のサブネット
resource "oci_core_subnet" "lb_subnet_backup" {
  count = "${local.is_need_lb ? 1 : 0 }"
  display_name = "LB backup subnet"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  availability_domain = "${lookup(local.availability_domain_prefix, var.env["runtime_region_shortname"])}${var.env["availability_domain_number_for_backup"]}"
  dns_label = "lbb"
  cidr_block = "${local.lb_backup_cidr}"
  security_list_ids = [
    "${compact(list(local.em_mode == "LB" ? oci_core_security_list.sl_for_access_em.id : "",
    local.weblogic_admin_mode == "LB" ? oci_core_security_list.sl_for_access_wls_admin.id : "",
    local.app_mode == "LB" ? oci_core_security_list.sl_for_access_app.id : "",
    oci_core_security_list.sl_for_lb.id))}"]

}

# Application 用のサブネット
resource "oci_core_subnet" "app_subnet" {
  display_name = "app subnet"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  availability_domain = "${local.availability_domain}"
  dns_label = "app"
  cidr_block = "${local.app_cidr}"
  security_list_ids = [
    "${compact(list(local.em_mode == "SSH" ? oci_core_security_list.sl_for_access_em.id : "",
    oci_core_security_list.sl_for_accept_app.id,
    oci_core_security_list.sl_for_accept_wls_admin.id,
    oci_core_security_list.sl_for_app_server.id,
    oci_core_vcn.primary_vcn.default_security_list_id))}"]

}

# Application が使う Database 用のサブネット
resource "oci_core_subnet" "app_db_subnet" {
  display_name = "app db subnet"
  compartment_id = "${oci_core_vcn.primary_vcn.compartment_id}"
  vcn_id = "${oci_core_vcn.primary_vcn.id}"
  availability_domain = "${local.availability_domain}"
  dns_label = "appdb"
  cidr_block = "${local.app_db_cidr}"
  security_list_ids = [
    "${compact(list(local.weblogic_admin_mode == "SSH" ? oci_core_security_list.sl_for_access_wls_admin.id : "",
    local.app_mode == "SSH" ? oci_core_security_list.sl_for_access_app.id : "",
    oci_core_security_list.sl_for_accept_em.id,
    oci_core_security_list.sl_for_db.id,
    oci_core_vcn.primary_vcn.default_security_list_id))}"]

}
