#!/bin/bash

set -x -e

INCLUDES_PATH=includes
TMP_DIR=/tmp

latest_backup() {
INPUT_DIR=$BASE_IN
for i in {1..4}; do
  latest=$(ls $INPUT_DIR|sort -rn|head -1)
  INPUT_DIR=$INPUT_DIR/$latest
done
}

# Import variables
source $INCLUDES_PATH/variables.sh

BASE_IN=backup

# Find latest backup
latest_backup
echo $INPUT_DIR

gunzip $INPUT_DIR/backup_site_kc.sql.gz -c > $TMP_DIR/backup_site_kc.sql
mysql -u ${db_redesign_user} -p"${db_redesign_user_pass}" -h ${db_redesign_host} kortingscode_site < $TMP_DIR/backup_site_kc.sql
gunzip $INPUT_DIR/backup_user.sql.gz -c > $TMP_DIR/backup_user.sql
mysql -u ${db_redesign_user} -p"${db_redesign_user_pass}" -h ${db_redesign_host} kortingscode_user < $TMP_DIR/backup_user.sql

for locale in "${locales[@]}"
do
    echo "Importing database ${locale}..."
    gunzip $INPUT_DIR/backup_site_${locale,,}.sql.gz -c > $TMP_DIR/backup_site_${locale,,}.sql
    mysql -u ${db_redesign_user} -p"${db_redesign_user_pass}" -h ${db_redesign_host} kortingscode_user < $TMP_DIR/backup_site_${locale,,}.sql
done
