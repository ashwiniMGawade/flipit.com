# Set timezone
echo "Europe/Amsterdam" | tee /etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Apache changes
echo "ServerName localhost" >> /etc/apache2/apache2.conf
a2enmod rewrite headers proxy proxy_http
cp -r /var/custom_config_files/apache2/* /etc/apache2/sites-available/
a2ensite dev.flipit.com developer.dev.flipit.com api.dev.flipit.com

# Changing the apache user to write in the shared folders
sudo sed -i 's/APACHE_RUN_USER=.*/APACHE_RUN_USER=vagrant/g' /etc/apache2/envvars
sudo sed -i 's/APACHE_RUN_GROUP=.*/APACHE_RUN_GROUP=www-data/g' /etc/apache2/envvars

# Configure PHP
php5enmod mcrypt
sed -i '/;sendmail_path =/c sendmail_path = /usr/bin/env catchmail' /etc/php5/apache2/php.ini
sed -i '/display_errors = Off/c display_errors = On' /etc/php5/apache2/php.ini
sed -i '/error_reporting = E_ALL & ~E_DEPRECATED/c error_reporting = E_ALL | E_STRICT' /etc/php5/apache2/php.ini
sed -i '/html_errors = Off/c html_errors = On' /etc/php5/apache2/php.ini
sed -i '/session.gc_maxlifetime = 1440/c session.gc_maxlifetime = 604800' /etc/php5/apache2/php.ini

# Remove default site
rm -rf /var/www/html