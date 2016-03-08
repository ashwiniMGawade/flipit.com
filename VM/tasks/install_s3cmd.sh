echo "installing s3cmd"
sudo apt-get install -y s3cmd
cp /var/custom_config_files/s3cmd/.s3cfg /home/vagrant/
cp /var/custom_config_files/s3cmd/.s3cfg /root/