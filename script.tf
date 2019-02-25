data "oci_core_private_ips" "db_instance_private_ips" {
  depends_on = [
    "oci_database_db_system.application_database"]
  subnet_id = "${oci_core_subnet.app_db_subnet.id}"
}

data "oci_core_public_ip" "db_instance_public_ip" {
  private_ip_id = "${data.oci_core_private_ips.db_instance_private_ips.private_ips.0.id}"
}

resource "null_resource" "initialize_database" {
  depends_on = [
    "oci_core_default_security_list.primary_default_security_list",
    "oci_core_default_route_table.primary_default_route_table"]
  connection {
    agent = false
    timeout = "1m"
    host = "${data.oci_core_public_ip.db_instance_public_ip.ip_address}"
    user = "opc"
    private_key = "${file("${var.env["ssh_private_key_file"]}")}"
  }
  provisioner "file" {
    source = "database"
    destination = "/home/opc/database/"
  }
  provisioner "remote-exec" {
    inline = [
      <<EOS
sudo mv database /home/oracle/
sudo chown -R oracle:oinstall /home/oracle/database
sudo su - oracle -c "sqlplus sys/${var.app_db["admin_password"]}@${oci_database_db_system.application_database.hostname}:1521/${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain} as sysdba @database/create_user.sql ${var.app_db["name"]} ${var.app_db["app_user"]} ${var.app_db["app_password"]}"
sudo su - oracle -c "sqlplus ${var.app_db["app_user"]}/${var.app_db["app_password"]}@${oci_database_db_system.application_database.hostname}:1521/${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain} @database/build.sql"
EOS
    ]
  }
}


# Application Server の管理サーバの Private IP
data "oci_core_private_ips" "admin_instance_private_ip" {
  depends_on = [
    "oraclepaas_java_service_instance.application_server"]

  #Optional
  subnet_id = "${oci_core_subnet.app_subnet.id}"

  filter = {
    name = "display_name"
    values = [
      ".+${var.app_server["display_name"]}.+vm-1"]
    regex = true
  }
}
# https://www.terraform.io/docs/providers/oci/d/core_private_ips.html

# Application Server の管理サーバの Public IP
data "oci_core_public_ip" "admin_instance_public_ip" {
  private_ip_id = "${data.oci_core_private_ips.admin_instance_private_ip.private_ips.0.id}"
}
# https://www.terraform.io/docs/providers/oci/r/core_public_ip.html

# Application Server の設定
resource "null_resource" "initialize_appserver" {
  depends_on = [
    "oci_core_default_security_list.primary_default_security_list",
    "oci_core_default_route_table.primary_default_route_table"]
  connection {
    agent = false
    timeout = "1m"
    host = "${data.oci_core_public_ip.admin_instance_public_ip.ip_address}"
    user = "opc"
    private_key = "${file("${var.env["ssh_private_key_file"]}")}"
  }
  provisioner "file" {
    source = "app_server"
    destination = "/home/opc/app_server/"
  }
  provisioner "remote-exec" {
    inline = [
      <<EOS
# ファイルをコピーして oracle ユーザに権限付与
sudo mv ~opc/app_server ~oracle/
sudo chmod -R u+x ~oracle/app_server/*.sh
sudo chown -R oracle:oracle ~oracle/app_server

# WebLogic Server Build Tooling をインストール
sudo su - oracle -c "sh ./app_server/install.sh"

# アプリケーション用のデータソースを作成
sudo su - oracle -c "sh ./app_server/create_datasource.sh ${var.app_db["app_user"]} ${var.app_db["app_password"]} ${oci_database_db_system.application_database.hostname}.${oci_database_db_system.application_database.domain} ${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain} ${data.oci_core_private_ips.admin_instance_private_ip.private_ips.0.ip_address} ${var.app_server["admin_user"]} ${var.app_server["admin_password"]} ${substr(var.app_server["display_name"],0,8)} ${(var.app_server["edition"] == "SE") ? format("%s_server_1",substr(var.app_server["display_name"],0,8)) : "ApplicationCluster"}"
EOS
    ]
  }
}