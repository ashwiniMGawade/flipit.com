# If phpmyadmin does not exist, install it
if [ ! -f /etc/phpmyadmin/config.inc.php ];
then

    # Used debconf-get-selections to find out what questions will be asked
    # This command needs debconf-utils

    # Handy for debugging. clear answers phpmyadmin: echo PURGE | debconf-communicate phpmyadmin

    echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

    echo 'phpmyadmin phpmyadmin/app-password-confirm password root' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/mysql/admin-pass password root' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/password-confirm password root' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/setup-password password root' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/database-type select mysql' | debconf-set-selections
    echo 'phpmyadmin phpmyadmin/mysql/app-pass password root' | debconf-set-selections

    echo 'dbconfig-common dbconfig-common/mysql/app-pass password root' | debconf-set-selections
    echo 'dbconfig-common dbconfig-common/mysql/app-pass password' | debconf-set-selections
    echo 'dbconfig-common dbconfig-common/password-confirm password root' | debconf-set-selections
    echo 'dbconfig-common dbconfig-common/app-password-confirm password root' | debconf-set-selections
    echo 'dbconfig-common dbconfig-common/app-password-confirm password root' | debconf-set-selections
    echo 'dbconfig-common dbconfig-common/password-confirm password root' | debconf-set-selections

    apt-get -y install phpmyadmin

    sudo sed -i 's/cookie/config/g' /etc/phpmyadmin/config.inc.php
    sudo sed -i "65i \$cfg['Servers'][\$i]['user']         = 'root';" /etc/phpmyadmin/config.inc.php
    sudo sed -i "66i \$cfg['Servers'][\$i]['password']     = 'root';" /etc/phpmyadmin/config.inc.php
fi

sudo sed -i s/pma_bookmark/pma__bookmark/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_relation/pma__relation/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_table_info/pma__table_info/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_table_coords/pma__table_coords/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_pdf__pages/pma_pdf__pages/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_column__info/pma_column__info/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_history/pma__history/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_table_uiprefs/pma__table_uiprefs/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_designer_coords/pma__designer_coords/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_tracking/pma__tracking/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_userconfig/pma__userconfig/g /etc/phpmyadmin/config.inc.php
sudo sed -i s/pma_recent/pma__recent/g /etc/phpmyadmin/config.inc.php
