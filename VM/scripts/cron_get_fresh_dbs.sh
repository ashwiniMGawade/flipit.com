#!/bin/bash

# Import variables.
source /var/scripts/variables.sh

echo "Deleting old Db's"
rm -rf $fresh_db_dir/*.sql.gz
rm -rf $fresh_db_dir/*.sql 
rm -rf $fresh_db_dir/*.tar.gz
rm -rf $fresh_db_dir/*.tar

echo "Downloading databases from production server."
cd $fresh_db_dir

s3cmd get --recursive --force s3://flipitbackup/dev/
tar -zxf $fresh_db_dir/devDbBackup.tar.gz -C $fresh_db_dir/