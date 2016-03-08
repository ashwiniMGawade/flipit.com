# Install cronjobs
cp -n /var/custom_config_files/cron.d/flipit.sh /etc/cron.d/flipit

# create tmp dir.
mkdir -p /var/www/flipit_application/web/public/tmp
chmod 777 /var/www/flipit_application/web/public/tmp
