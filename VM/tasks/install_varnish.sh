echo "installing varnish"
apt-get install apt-transport-https
curl https://repo.varnish-cache.org/ubuntu/GPG-key.txt | apt-key add -
echo "deb https://repo.varnish-cache.org/ubuntu/ precise varnish-3.0" >> /etc/apt/sources.list.d/varnish-cache.list
apt-get update
apt-get install -y varnish

rm -f /etc/varnish/default.vcl
cp -R /var/custom_config_files/varnish/vcl/* /etc/varnish/

rm -f /etc/default/varnish
cp /var/custom_config_files/varnish/varnish /etc/default/

sudo service varnish restart