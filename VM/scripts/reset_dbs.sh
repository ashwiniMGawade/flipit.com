#!/bin/bash

# Import variables.
source /var/scripts/variables.sh

# Get the Db from the server if not downloaded yet
# if find $fresh_db_dir ! -name '.gitkeep' | read;
# then
#     source /var/scripts/cron_get_fresh_dbs.sh
# fi

echo "#######################################"
echo "##### Resettings DB's                  "
echo "#######################################"

echo "Dumbing existing KC databases."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --execute="DROP DATABASE kortingscode_site;"
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --execute="DROP DATABASE kortingscode_user;"

echo "Creating KC databases."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --batch --execute="CREATE DATABASE kortingscode_site;"
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --batch --execute="CREATE DATABASE kortingscode_user;"

echo "Importing KC databases."
mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" "kortingscode_site" < "${fresh_db_dir}/backup_site_kc.sql"
mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" "kortingscode_user" < "${fresh_db_dir}/backup_user.sql"

echo "Granting flipit user on KC databases."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --execute="GRANT ALL PRIVILEGES  ON kortingscode_site.* TO '${db_user_pass}'@'${db_host}' IDENTIFIED BY '${db_user_pass}' WITH GRANT OPTION;"
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --execute="GRANT ALL PRIVILEGES  ON kortingscode_user.* TO '${db_user_pass}'@'${db_host}' IDENTIFIED BY '${db_user_pass}' WITH GRANT OPTION;"

for locale in "${locales[@]}"
do
    echo "Dumbing existing $locale database."
    mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --execute="DROP DATABASE flipit_$locale;"
    
    echo "Creating $locale database."
    mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --batch --execute="CREATE DATABASE flipit_$locale;"
    
    echo "Importing $locale database."
    mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  "flipit_$locale" < "${fresh_db_dir}/backup_site_$locale.sql"
    
    echo "Grating flipit user on $locale database."
    mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --execute="GRANT ALL PRIVILEGES  ON flipit_$locale.* TO '${db_user_pass}'@'${db_host}' IDENTIFIED BY '${db_user_pass}' WITH GRANT OPTION;"
done

echo "Changing kim@web-flight.nl admin password to 'password'."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" -e 'UPDATE `kortingscode_user`.`user` SET `password` = MD5( "password" ) WHERE `user`.`id` =1;'

echo "#### DB's are reset."