#!/bin/bash

echo "Creating Datasource"

db_user=$1
db_password=$2
db_hostname=$3
db_service=$4
wls_admin_server=$5
wls_admin_user=$6
wls_admin_password=$7
domain_name=$8
target=$9

sed -i s/_db_user_/${db_user}/ app_server/datasource_param.yml
sed -i s/_db_password_/${db_password}/ app_server/datasource_param.yml
sed -i s/_db_service_/${db_service}/ app_server/datasource_param.yml
sed -i s/_db_hostname_/${db_hostname}/ app_server/datasource_param.yml
sed -i s/_wls_target_/${target}/ app_server/datasource_param.yml

echo "${wls_admin_password}" | weblogic-deploy/bin/updateDomain.sh -oracle_home /u01/app/oracle/middleware -domain_type WLS -domain_home /u01/data/domains/${domain_name}_domain -admin_url t3://${wls_admin_server}:7001 -admin_user ${wls_admin_user} -model_file app_server/datasource.yml -variable_file app_server/datasource_param.yml
