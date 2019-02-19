output "app_info" {
  value = {
    app_url = "https://<IP>/sample-app/"
    admin_tool_url = "https://<IP>:7002/console/"
  }
}

output "app_db_info" {
  value = {
    hostname = "${oci_database_db_system.application_database.hostname}"
    port = "tcp:1521"
    servicename = "${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain}"
    db_name = "${oci_database_db_system.application_database.db_home.0.database.0.db_name}"
    pdb = "${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}"
    admin = "sys"
    jdbc_url = "jdbc:oracle:thin:@//<IP>:1521/${oci_database_db_system.application_database.db_home.0.database.0.pdb_name}.${oci_database_db_system.application_database.domain}"
    admin_url = "https://<IP>:5500/em"
  }
}
