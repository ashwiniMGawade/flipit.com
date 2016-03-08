echo "installing memcache"
sudo apt-get install -y php5-memcache
sudo apt-get install -y php5-memcached memcached
sudo service memcached restart
