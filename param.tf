# OCI
variable "oraclecloud" {
  type = "map"
  default = {
    tenancy_ocid = ""
    user_ocid = ""
    fingerprint = ""
    private_key_path = ""
    user = ""
    password = ""
    identity_domain = ""
  }
}


variable "bring_your_own_license" {
  type = "map"
  default = {
    database = false
    weblogic = false
  }
}


variable "env" {
  type = "map"
  default = {
    runtime_region_shortname = "PHX"
    primary_compartment_ocid = ""
    availability_domain_number = "3"
    availability_domain_number_for_backup = "2"
    primary_vcn_name = "primary_vcn"
    primary_dns_label = "psm"
    ssh_public_key = ""
    domain_name = ""
  }
}

variable "backup" {
  type = "map"
  default = {
    enable = false
    compartment_id = ""
    bucket_name = "Backup"
    storage_type = "Standard"
    username = ""
    auth_token = ""
  }
}

# リポジトリデータベース

variable "repodb" {
  type = "map"
  default = {
    name = "repository_db"
    shape = "VM.Standard2.1"
    version = "12.2.0.1"
    password = "Welcome1#"
  }
}


variable "app_server" {
  type = "map"
  default = {
    edition = "SE"
    version = "12.2.1.3.181116"
    display_name = "ApplicationServer"
    mode = "DEVELOPMENT"
    admin_user = "weblogic"
    admin_password = "Welcome1#"
    admin_access_mode = "SSH"
    shape_admin = "VM.Standard2.1"
    shape_app_server = "VM.Standard2.1"
    shape_http_session = "VM.Standard2.1"
    count_app_server = 1
    count_http_session = 0
  }
}


variable "app_db" {
  type = "map"
  default = {
    edition = "STANDARD_EDITION"
    shape = "VM.Standard2.1"
    version = "18.3.0.0"
    display_name = "Database for App"
    hostname = "runtime-db"
    admin_password = "Db#1Welcome1#"
    admin_access_mode = "SSH"
    storage_size = 256
    disk_redundancy = "HIGH"
    name = "pdb1"
  }
}

variable "lb" {
  type = "map"
  default = {
    display_name = "Application LB"
    shape = "100Mbps"
  }
}


#対応させるパラメータ

variable "app" {
  type = "map"
  default = {
    access_mode = "LB"
    context = "sample-app"
  }
}

locals {
  availability_domain = "${lookup(local.availability_domain_prefix, var.env["runtime_region_shortname"])}${var.env["availability_domain_number"]}"
  availability_domain_for_backup = "${lookup(local.availability_domain_prefix, var.env["runtime_region_shortname"])}${var.env["availability_domain_number_for_backup"]}"
  region = "${lookup(data.oci_identity_regions.regions.regions[0], "name")}"

  app_mode = "${lookup(var.app,"access_mode") == "LB" ? "LB" : (lookup(var.app,"access_mode") == "SSH" ? "SSH" : "DIRECT")}"
  em_mode = "${lookup(var.app_db,"admin_access_mode") == "LB" ? "LB" : (lookup(var.app_db,"admin_access_mode") == "SSH" ? "SSH" : "DIRECT")}"
  weblogic_admin_mode = "${lookup(var.app_server,"admin_access_mode") == "LB" ? "LB" : (lookup(var.app_server,"admin_access_mode") == "SSH" ? "SSH" : "DIRECT")}"

  is_need_lb = "${contains(list(local.app_mode, local.em_mode, local.weblogic_admin_mode), "LB")}"
  app_http_port = 80
  app_https_port = 443
  admin_http_port = 7001
  admin_https_port = 7002
  em_express_port = 5500
  db_connection_port = 1521

  vcn_cidr = "10.0.0.0/16"
  lb_primary_cidr = "10.0.3.0/24"
  lb_backup_cidr = "10.0.10.0/24"
  app_cidr = "10.0.1.0/24"
  app_db_cidr = "10.0.2.0/24"
  repo_db_cidr = "10.0.0.0/24"
  internet_cidr = "0.0.0.0/0"
  icmp = "1"
  tcp = "6"
  udp = "17"

  weblogic_admin_rule = {
    "LB" = [
      {
        protocol = "${local.tcp}"
        source = "${local.lb_primary_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_http_port}"
            "max" = "${local.admin_http_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_backup_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_http_port}"
            "max" = "${local.admin_http_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_primary_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_https_port}"
            "max" = "${local.admin_https_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_backup_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_https_port}"
            "max" = "${local.admin_https_port}"
          }]
      }
    ]
    "DIRECT" = [
      {
        protocol = "${local.tcp}"
        source = "${local.internet_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_https_port}"
            "max" = "${local.admin_https_port}"
          }]
      }
    ]
    "SSH" = [
      {
        protocol = "${local.tcp}"
        source = "${local.vcn_cidr}"
        tcp_options = [
          {
            "min" = "${local.admin_https_port}"
            "max" = "${local.admin_https_port}"
          }]
      }
    ]
  }

  application_rule = {
    "LB" = [
      {
        protocol = "${local.tcp}"
        source = "${local.lb_primary_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_https_port}"
            "max" = "${local.app_https_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_backup_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_https_port}"
            "max" = "${local.app_https_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_primary_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_http_port}"
            "max" = "${local.app_http_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_backup_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_http_port}"
            "max" = "${local.app_http_port}"
          }]
      }
    ]
    "DIRECT" = [
      {
        protocol = "${local.tcp}"
        source = "${local.internet_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_https_port}"
            "max" = "${local.app_https_port}"
          }]
      }
    ]
    "SSH" = [
      {
        protocol = "${local.tcp}"
        source = "${local.vcn_cidr}"
        tcp_options = [
          {
            "min" = "${local.app_https_port}"
            "max" = "${local.app_https_port}"
          }]
      }
    ]
  }

  em_rule = {
    "LB" = [
      {
        protocol = "${local.tcp}"
        source = "${local.lb_primary_cidr}"
        tcp_options = [
          {
            "min" = "${local.em_express_port}"
            "max" = "${local.em_express_port}"
          }]
      },
      {
        protocol = "${local.tcp}"
        source = "${local.lb_backup_cidr}"
        tcp_options = [
          {
            "min" = "${local.em_express_port}"
            "max" = "${local.em_express_port}"
          }]
      }
    ]
    "DIRECT" = [
      {
        protocol = "${local.tcp}"
        source = "${local.internet_cidr}"
        tcp_options = [
          {
            "min" = "${local.em_express_port}"
            "max" = "${local.em_express_port}"
          }]
      }
    ]
    "SSH" = [
      {
        protocol = "${local.tcp}"
        source = "${local.vcn_cidr}"
        tcp_options = [
          {
            "min" = "${local.em_express_port}"
            "max" = "${local.em_express_port}"
          }]
      }
    ]
  }

  cluster = {
    "APOnly" = [
      {
        name = "ApplicationCluster"
        type = "APPLICATION_CLUSTER"
        shape = "${var.app_server["shape_app_server"]}"
        server_count = "${var.app_server["count_app_server"]}"
      },
    ]
    "APandCache" = [
      {
        name = "ApplicationCluster"
        type = "APPLICATION_CLUSTER"
        shape = "${var.app_server["shape_app_server"]}"
        server_count = "${var.app_server["count_app_server"]}"
      },
      {
        type = "CACHING_CLUSTER"
        name = "HttpSessionCluster"
        shape = "${var.app_server["shape_http_session"]}"
        server_count = "${var.app_server["count_http_session"]}"
      }]
  }
}
