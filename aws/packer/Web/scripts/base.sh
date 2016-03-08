#!/bin/bash

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' |sudo tee -a /etc/sudoers
PP=/tmp/provision
export DEBIAN_FRONTEND=noninteractive

# Configure APT
(
  echo 'Acquire::http {No-Cache=True;};' |sudo tee /etc/apt/apt.conf.d/no-cache
  sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe restricted multiverse"
  sudo apt-add-repository -y ppa:ondrej/php5-oldstable
  sudo apt-add-repository -y ppa:mikko-red-innovation/ppa
  sudo aptitude update
)

# Update and Install Packages
(
  echo "######################################"
  echo "# Installing Packages                #"
  echo "######################################"
  sudo aptitude upgrade -y
  sudo aptitude install -y \
      build-essential \
      git \
      vim \
      apache2 \
      php5-fpm \
      php-pear \
      php5-dev \
      php-net-ftp \
      php5-mcrypt \
      php5-xsl \
      php5-gd \
      php5-curl \
      php5-mysql \
      php-soap \
      php-gettext \
      phpmyadmin \
      s3cmd \
      libapache2-mod-php5 \
      mysql-server \
      python-pip \
      ruby1.9.1
)


# Configure boto
(
 echo "######################################"
 echo "# Setting up boto                    #"
 echo "######################################"
 sudo pip install boto
)

#Setup S3FS
(
  echo "######################################"
  echo "# Setting up S3FS                    #"
  echo "######################################"
  cd $HOME
  sudo DEBIAN_FRONTEND=$DEBIAN_FRONTEND aptitude install -y libfuse-dev fuse-utils libcurl4-openssl-dev libxml2-dev mime-support
  wget -c -t20 https://s3fs.googlecode.com/files/s3fs-1.73.tar.gz
  tar -zxf s3fs-1.73.tar.gz
  cd s3fs-1.73
  ./configure
  make
  sudo make install
)

(
  echo "######################################"
  echo "# Setting up NODE NPM AND LESS       #"
  echo "######################################"
  git clone https://github.com/joyent/node.git
  cd node
  ./configure
  make
  sudo make install
  curl https://npmjs.org/install.sh | sudo sh
  npm install less
  echo 'export PATH=$HOME/node/node_modules/.bin/:$PATH' |sudo -u $USER tee -a /home/$USER/.profile
)

(
  echo "######################################"
  echo "# Setting up composer                #"
  echo "######################################"
  curl -sS https://getcomposer.org/installer | php
  sudo mv composer.phar /usr/local/bin/composer
)