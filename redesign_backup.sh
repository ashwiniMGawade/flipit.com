#!/bin/bash

set -x -e

INCLUDES_PATH=includes

# Import variables.
source $INCLUDES_PATH/variables.sh

TABLES_FILE=$INCLUDES_PATH/redesign_tables/site.in
TABLES_USER_FILE=$INCLUDES_PATH/redesign_tables/user.in
YEAR=$(date '+%Y')
MONTH=$(date '+%m')
DAY_OF_MONTH=$(date '+%d')
HOUR_MIN=$(date '+%H%M')

# Create output directory
BASE_OUT=backup
OUTPUT_DIR="$BASE_OUT/${YEAR}/${MONTH}/${DAY_OF_MONTH}/${HOUR_MIN}"
mkdir -p $OUTPUT_DIR

mysqldump --opt -u ${db_user} -p"${db_user_pass}" -h ${db_host} kortingscode_site $(xargs < $TABLES_FILE)  | gzip -c | cat > $OUTPUT_DIR/backup_site_kc.sql.gz
mysqldump --opt -u ${db_user} -p"${db_user_pass}" -h ${db_host} kortingscode_user  $(xargs < $TABLES_USER_FILE) | gzip -c | cat > $OUTPUT_DIR/backup_user.sql.gz

for locale in "${locales[@]}"
do
    echo "Dumping database ${locale}..."
    mysqldump --opt -u ${db_user} -p"${db_user_pass}" -h ${db_host} flipit_${locale,,} $(xargs < $TABLES_FILE) | gzip -c | cat > $OUTPUT_DIR/backup_site_${locale,,}.sql.gz
done
