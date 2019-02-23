data "oci_core_private_ips" "db_instance_private_ips" {
  depends_on = ["oci_database_db_system.application_database"]
  subnet_id = "${oci_core_subnet.app_db_subnet.id}"
}

data "oci_core_public_ip" "db_instance_public_ip"{
  private_ip_id = "${data.oci_core_private_ips.db_instance_private_ips.private_ips.0.id}"
}

resource "null_resource" "initialize_database" {
  depends_on = ["oci_core_default_security_list.primary_default_security_list", "oci_core_default_route_table.primary_default_route_table"]
  connection {
    agent       = false
    timeout     = "1m"
    host        = "${data.oci_core_public_ip.db_instance_public_ip.ip_address}"
    user        = "opc"
    private_key = "${file("${var.env["ssh_private_key_file"]}")}"
  }
  provisioner "file" {
    source = "database"
    destination = "/home/opc/database/"
  }
  provisioner "remote-exec" {
    inline = [ <<EOS
sudo mv database /home/oracle/
sudo chown -R oracle:oinstall /home/oracle/database
sudo su - oracle -c "sqlplus sys/${var.app_db["admin_password"]}@${oci_database_db_system.application_database.hostname}:1521/${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain} as sysdba @database/create_user.sql ${var.app_db["name"]} ${var.app_db["app_user"]} ${var.app_db["app_password"]}"
sudo su - oracle -c "sqlplus ${var.app_db["app_user"]}/${var.app_db["app_password"]}@${oci_database_db_system.application_database.hostname}:1521/${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain} @database/build.sql"
EOS
    ]
  }
}

