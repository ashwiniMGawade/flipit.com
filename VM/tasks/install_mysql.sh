# Import variables.
source /var/scripts/variables.sh

# Install MySQL
sudo debconf-set-selections <<< 'mysql-server-<version> mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server-<version> mysql-server/root_password_again password root'
sudo apt-get -y install mysql-server

# Setup database user
echo "CREATE USER '${db_user}'@'localhost' IDENTIFIED BY '${db_user_pass}'" | mysql -uroot -proot
echo "GRANT ALL PRIVILEGES ON * . * TO '${db_user}'@'localhost' WITH GRANT OPTION;" | mysql -uroot -proot
echo "FLUSH PRIVILEGES;" | mysql -uroot -proot
