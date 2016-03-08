#!/bin/bash

# Import variables.
source /var/scripts/variables.sh

# Fetch DB's when non available
count=`ls -la /var/sqldump/*.tar.gz 2>/dev/null | wc -l`
if [ $count == 0 ]; then
	source /var/scripts/cron_get_fresh_dbs.sh
fi

# Import databases where there are not DB's available
existing_db=`mysqlshow -u $user -p$password $kc_site_db_name | grep -v Wildcard | grep -o $kc_site_db_name`
if [ "$existing_db" != "$kc_site_db_name" ]; then
    source /var/scripts/reset_dbs.sh
fi

# Get fetch language when non available
count=`ls -1 /var/www/flipit_application/web/public/language/*.mo 2>/dev/null | wc -l`
if [ $count == 0 ]; then
	source /var/scripts/cron_get_language_files.sh
fi

# Start mailcatcher
mailcatcher --http-ip=192.168.56.102