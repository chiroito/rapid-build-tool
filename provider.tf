# OCI プロバイダの設定
provider "oci" {
  region = "us-phoenix-1"
  tenancy_ocid = "${var.oraclecloud["tenancy_ocid"]}"
  user_ocid = "${var.oraclecloud["user_ocid"]}"
  fingerprint = "${var.oraclecloud["fingerprint"]}"
  private_key_path = "${var.oraclecloud["private_key_path"]}"
}

provider "oraclepaas" {
  user = "${var.oraclecloud["user"]}"
  password = "${var.oraclecloud["password"]}"
  identity_domain = "${var.oraclecloud["identity_domain"]}"
  database_endpoint = "https://dbaas.oraclecloud.com/"
  java_endpoint = "https://jaas.oraclecloud.com/"
}