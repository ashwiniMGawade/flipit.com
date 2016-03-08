MAILTO=""

# Getting production files to development
40 10 * * * cd /var/scripts && bash cron_get_fresh_dbs.sh 
30 10 * * * cd /var/scripts && bash cron_get_language_files.sh
00 10 * * * cd /var/scripts && bash cron_get_images.sh

