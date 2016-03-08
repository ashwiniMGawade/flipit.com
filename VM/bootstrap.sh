#!/usr/bin/env bash

# Import variables.
source /var/scripts/variables.sh

# Update repositories before installing anything
apt-get update

source /var/tasks/install_apache_php.sh

source /var/tasks/install_mysql.sh

source /var/tasks/install_phpmyadmin.sh

source /var/tasks/install_s3cmd.sh

source /var/tasks/install_mailcatcher.sh

source /var/tasks/install_varnish.sh

source /var/tasks/install_memcache.sh

source /var/tasks/configure_apache_php.sh

source /var/tasks/setup_flipit.sh

source /var/scripts/gtDataGeneration.sh

# Make sure things are up and running as they should be
service apache2 restart