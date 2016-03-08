#!/bin/bash

includes_path=includes

# Import variables.
source $includes_path/variables.sh

echo "#######################################"
echo "##### Resettings DB's                  "
echo "#######################################"

echo "Creating temporary database directory."
mkdir $dir_to_db

echo "Downloading databases from production server."
cd $dir_to_db

# Uncomment to reset databases in NL
s3cmd get --recursive --force s3://flipitbackup/dev/

# Uncomment to reset databases in India
# rsync -rltuDv seasia-php@121.241.123.113:/var/www/flipit.com/dbbackups .

echo "Extracting databases."
tar -zxf $dir_to_db/devDbBackup.tar.gz -C $dir_to_db/

echo "Dumbing existing KC databases."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --execute="DROP DATABASE kortingscode_site;"
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --execute="DROP DATABASE kortingscode_user;"

echo "Creating KC databases."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --batch --execute="CREATE DATABASE kortingscode_site;"
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" --batch --execute="CREATE DATABASE kortingscode_user;"

echo "Importing KC databases."
mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" "kortingscode_site" < "${dir_to_db}/backup_site_kc.sql"
mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" "kortingscode_user" < "${dir_to_db}/backup_user.sql"

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
    mysql --max_allowed_packet=2000M -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  "flipit_$locale" < "${dir_to_db}/backup_site_$locale.sql"
    
    echo "Grating flipit user on $locale database."
    mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}"  --execute="GRANT ALL PRIVILEGES  ON flipit_$locale.* TO '${db_user_pass}'@'${db_host}' IDENTIFIED BY '${db_user_pass}' WITH GRANT OPTION;"
done

echo "Changing kim@web-flight.nl admin password to 'password'."
mysql -u "${db_user}" -p"${db_user_pass}" -h"${db_host}" -e 'UPDATE `kortingscode_user`.`user` SET `password` = MD5( "password" ) WHERE `user`.`id` =1;'

echo "Deleting temporary database directory."
rm -rf $dir_to_db

echo "#### DB's are reset."
