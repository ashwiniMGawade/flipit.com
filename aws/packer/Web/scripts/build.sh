#!/bin/bash

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' |sudo tee -a /etc/sudoers
PP=/tmp/provision
export DEBIAN_FRONTEND=noninteractive

export ROOT=/var/www
export USER=flipit
export WWW_USER=www-data
export USER_HOME=/home/$USER
export FLIPIT_REPO=git@bitbucket.org:webflight/flipit.com.git
export BACKUP_DIR=$ROOT/flipit.com/backup
export SHARE_DIR=$ROOT/flipit.com/shared
export LOCAL_DIR=$ROOT/flipit.com/local
export LANGUAGE_DIR=$ROOT/flipit.com/language

# Preseed Debconf
(
cat <<'EOF'
nullmailer  nullmailer/defaultdomain  string  kortingscode.nl
nullmailer  shared/mailname string  kortingscode.nl
nullmailer  nullmailer/adminaddr  string  info@webflight.nl
nullmailer  nullmailer/relayhost  string  smtp.mandrillapp.com smtp --port=587 --starttls --user=webflight@gimiscale.com --pass=FYeOEGSQRE3I6bKeOv6Clw
EOF
) |sudo debconf-set-selections

# Update and Install Packages
(
  echo "######################################"
  echo "# Installing Packages                #"
  echo "######################################"
  sudo aptitude update
  sudo aptitude install -y \
      curl \
      php5-memcache \
      php5-memcached \
      nullmailer=1:1.11-2~precise1~ppa1 \
      supervisor \
      libpcre3-dev \
      mutt \
      mc
  sudo apt-get install --only-upgrade bash
)

#Setup S3FS
(
  echo "######################################"
  echo "# Setting up S3FS                    #"
  echo "######################################"
  cd $HOME
  sudo DEBIAN_FRONTEND=$DEBIAN_FRONTEND aptitude install -y libfuse-dev fuse-utils libcurl4-openssl-dev libxml2-dev mime-support
  wget -c -t20 https://s3fs.googlecode.com/files/s3fs-1.74.tar.gz
  tar -zxf s3fs-1.74.tar.gz
  cd s3fs-1.74
  ./configure
  make
  sudo make install
)

export LESSC_PATH=/home/ubuntu/node/node_modules/.bin/
export PATH=$LESSC_PATH:$PATH
(
  echo 'export PATH=/home/ubuntu/node/node_modules/.bin/:$PATH' |sudo -u $USER tee -a /home/flipit/.profile
)

(
  echo "######################################"
  echo "#     Install php packages           #"
  echo "######################################"
  echo "Yes"| sudo pecl install memcache apc
)

# Make binary files executable and copy ROOT files
(
  set +x
  echo "########################################"
  echo "# Copy ROOT files                      #"
  echo "########################################"
  set -x
  chmod a+x $PP/ROOT/usr/*bin/*
  chmod a+x $PP/ROOT/root/*.sh
  chmod a+x $PP/ROOT/root/firstboot_scripts/*.sh
  chmod 0440 $PP/ROOT/etc/sudoers.d/flipit
  sudo rsync -rlptD --exclude='.git/' $PP/ROOT/ /
  ls -la /etc/php5/apache2/conf.d
)

# Configure active user
(
  echo "######################################"
  echo "# Setting up User                    #"
  echo "######################################"
  sudo useradd -d $USER_HOME -m $USER
  sudo chsh -s /bin/bash $USER
)

# Configure User SSH
(
  echo "######################################"
  echo "# Setting up SSH                    #"
  echo "######################################"
  sudo mkdir $USER_HOME/.ssh
  sudo cp $PP/ssh/* $USER_HOME/.ssh/
  sudo chown -R $USER:$USER $USER_HOME/.ssh
  sudo chmod 600 $USER_HOME/.ssh/id_rsa
  sudo chmod 600 $USER_HOME/.ssh/github
)

# Configure aws-cli
(
 echo "######################################"
 echo "# Setting up boto                    #"
 echo "######################################"
 echo "[Credentials]
aws_access_key_id = ${MASTER_AWS_ACCESS_KEY_ID}
aws_secret_access_key = ${MASTER_AWS_SECRET_ACCESS_KEY}"| sudo -u $USER tee $USER_HOME/.boto > /dev/null
)

# Configure awslog agent
(
  AWSLOGS_DIR=/var/lib/awslogs
  sudo mkdir -p /var/lib/awslogs
  cd $AWSLOGS_DIR
  sudo wget https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py
  sudo chmod +x ./awslogs-agent-setup.py
  sudo ./awslogs-agent-setup.py -n -r eu-west-1 -c /etc/awslogs.conf
)

# Configure phpmyadmin
(
  echo "######################################"
  echo "# Configure PhpMyAdmin               #"
  echo "######################################"
  sudo ln -s /etc/phpmyadmin/apache.conf /etc/apache2/sites-available/phpmyadmin.conf
  echo "\$cfg['ForceSSL'] = true;" | sudo tee -a /etc/phpmyadmin/config.inc.php
)


# Configure Apache
(
  echo "######################################"
  echo "# Setting up Apache                  #"
  echo "######################################"
  sudo a2enmod rewrite
  sudo a2enmod headers
  sudo a2enmod ssl
  sudo a2enmod proxy
  sudo a2enmod proxy_http

  sudo a2ensite phpmyadmin.conf
  sudo a2dissite 000-default
  sudo a2ensite 001-kortingscode.conf
  sudo mkdir -p  $ROOT/flipit.com
  sudo mkdir -p  $ROOT/health
)


# Create project Root path and (Shallow) Clone kortingscode and deploy repository
(
  echo "######################################"
  echo "# Cloning repository                #"
  echo "######################################"
  sudo chown -R $USER:$USER $ROOT
  sudo -u $USER git clone --depth 10 --recursive $FLIPIT_REPO $ROOT/flipit.com
  sudo -u $USER mv $ROOT/flipit.com.tmp/* $ROOT/flipit.com
  sudo -u $USER rmdir $ROOT/flipit.com.tmp
  cd $ROOT/flipit.com && sudo -u $USER git submodule foreach git fetch --all
  cd $ROOT/flipit.com && sudo -u $USER git submodule foreach git fetch -t
  cd $ROOT/flipit.com && sudo -u $USER git submodule foreach git checkout master
)

# Create Shared, Backup, and Local dir
(
  echo "######################################"
  echo "# Adding S3 dirs                     #"
  echo "######################################"
  sudo mkdir -p $SHARE_DIR $LOCAL_DIR $BACKUP_DIR $LANGUAGE_DIR
  sudo chown -R $USER:$USER $ROOT/flipit.com
)

#  Application.ini
(
  echo "######################################"
  echo "# Copying application.ini            #"
  echo "######################################"
  cd $ROOT/flipit.com
  sudo touch $ROOT/flipit.com/history_deploy.txt
  sudo chown -R $USER:$USER $ROOT/flipit.com
)

(
  echo "######################################"
  echo "# Setting up S3CMD                   #"
  echo "######################################"
  sudo cp $PP/s3/.s3cfg /home/$USER/
  sudo chown $USER:$USER /home/$USER/.s3cfg
  echo "access_key = $S3CMD_AWS_ACCESS_KEY_ID"| sudo tee -a /home/$USER/.s3cfg >/dev/null
  echo "secret_key = $S3CMD_AWS_SECRET_ACCESS_KEY"| sudo tee -a /home/$USER/.s3cfg >/dev/null
)

#Setup S3FS
(
  echo "######################################"
  echo "# Setting up S3FS                    #"
  echo "######################################"
  cd $HOME
  # S3 Credentials
  sudo sed -i  "s/AWS_KEY/$S3FS_AWS_ACCESS_KEY_ID/g" /etc/passwd-s3fs.erb
  sudo sed -i  "s/AWS_SECRET/$S3FS_AWS_SECRET_ACCESS_KEY/g" /etc/passwd-s3fs.erb
  sudo chmod 0640 /etc/passwd-s3fs.erb
  sudo chown root:fuse /etc/passwd-s3fs.erb

  # Give access to $USER and www user
  sudo usermod -a -G fuse $USER
  WUSER_ID=$(id -u $WWW_USER)
  WGROUP_ID=$(id -g $WWW_USER)
  USER_ID=$(id -u $USER)
  GROUP_ID=$(id -g $USER)
  EPHEMERAL=$(mount|awk '/xvdb/ { print $3}')

  FIRSTBOOT_DIR=/root/firstboot_scripts
  sudo chmod +x $FIRSTBOOT_DIR/*
  crontab -l | { cat; echo "@reboot sudo bash $FIRSTBOOT_DIR/s3fs_mount.sh $FIRSTBOOT_DIR/fstab"; } | crontab -
)

# Change timezone to AMS
(
  echo "######################################"
  echo "#     Changing timezone (AMS)        #"
  echo "######################################"
  sudo rm /etc/localtime
  sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
)

(
  echo 'export PATH=/home/ubuntu/node/node_modules/.bin/:$PATH' |sudo -u $USER tee -a /home/$USER/.profile
)

# Setup New Relic
(
  echo "######################################"
  echo "#     New Relic Setup                #"
  echo "######################################"
  echo newrelic-php5 newrelic-php5/license-key string "" | sudo debconf-set-selections
  echo newrelic-php5 newrelic-php5/application-name string "" | sudo debconf-set-selections
  # Download gpg key
  wget -O - https://download.newrelic.com/548C16BF.gpg | sudo apt-key add -
  sudo sh -c 'echo "deb http://apt.newrelic.com/debian/ newrelic non-free" > /etc/apt/sources.list.d/newrelic.list'

  # Install newrelic php agent
  sudo apt-get update
  sudo apt-get -y install newrelic-php5 newrelic-sysmond
)

(
  echo "######################################"
  echo "# Setting up SEO.log retrieval cron  #"
  echo "######################################"
  sudo gem install aws-sdk-core
  sudo chmod +x /usr/bin/seo-log-retrieval
  sudo mkdir /home/flipit/.mutt/
  echo 'set folder=""' | sudo tee --append /home/flipit/.mutt/muttrc
  sudo chown -R flipit: /home/flipit/.mutt
)


(
  echo "######################################"
  echo "# Starting cron service              #"
  echo "######################################"
  sudo service cron restart
  sudo touch /etc/cron.d/flipit
)
