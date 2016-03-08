#!/bin/bash

includes_path=includes

# Import variables.
source $includes_path/variables.sh
downloads=/Users/kimpellikaan/Downloads/DB

echo "##### Creating folders ..."
for locale in "${locales[@]}"
do
	# mkdir $downloads/$locale
	# rsync -rltuDv root@178.18.91.234:$prodpath/dbbackups/backups/backup_site_"$locale"_2014-02-17-13-10.sql.gz $downloads/$locale
	# gzip -d $downloads/$locale/backup_site_"$locale"_2014-02-17-13-10.sql.gz
	# mysql -u "root" -p"password" -e 'CREATE database backup_flipit_'$locale''
	# mysql -u "root" -p"password" backup_flipit_$locale < $downloads/$locale/backup_site_${locale}_2014-02-17-13-10.sql
	mysql -u "root" -p"password" -e 'SELECT `authorId`,`authorName`,`id` FROM `backup_flipit_'$locale'`.`offer` INTO OUTFILE "'$downloads'/'$locale'/data.csv" FIELDS TERMINATED BY ","'
    php $downloads/parse.php $locale $downloads/$locale
    # mysql -u root -ppassword < $downloads/$locale/backup_data.sql
done

# echo "##### Downloading DB's from production server ..."
# rsync -rltuDv root@178.18.91.234:$prodpath/dbbackups/backups/backup_site_kc_2014-02-17-13-10.sql.gz $downloads

# echo "##### Extracting the gzips ..."
# gzip -d $downloads/backup_site_kc_2014-02-17-13-10.sql.gz

# echo "##### Creating backup DB's ..."
# mysql -u "root" -p"password" -e 'CREATE database backup_flipit_kc'

# echo "##### Importing backup DB's ..."
# mysql -u "root" -p"password" backup_flipit_kc < $downloads/backup_site_kc_2014-02-17-13-10.sql

echo "##### Creating exports for contentmanagerid ..."
mysql -u "root" -p"password" -e 'SELECT `authorId`,`authorName`,`id` FROM `backup_flipit_kc`.`offer` INTO OUTFILE "'$downloads'/data.csv" FIELDS TERMINATED BY ","'

echo "##### Creating import sql files"
php $downloads/parse.php kc $downloads

# echo "##### Creating import sql files"
# mysql -u root -ppassword < $downloads/backup_data.sql


# echo "##### Clean all non used files ..."
# for locale in "${locales[@]}"
# do
# 	rm -rf $downloads/$locale/*
# done

echo "#### Done"


# echo "##### Creating folders ..."
# for locale in "${locales[@]}"
# do
#     mkdir $downloads/combined/$locale
#     mv $downloads/$locale/backup_data.sql $downloads/combined/$locale
# done