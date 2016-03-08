#!/bin/bash

echo 'Defaults env_keep += "DEBIAN_FRONTEND"' |sudo tee -a /etc/sudoers
PP=/tmp/provision
export DEBIAN_FRONTEND=noninteractive
export USER=flipit
export USER_HOME=/home/$USER

# Configure APT
(
  echo 'Acquire::http {No-Cache=True;};' |sudo tee /etc/apt/apt.conf.d/no-cache
  sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) main universe restricted multiverse"
  # Add varnish source repository
  curl http://repo.varnish-cache.org/debian/GPG-key.txt | sudo apt-key add -
  echo "deb http://repo.varnish-cache.org/ubuntu/ precise varnish-3.0" | sudo tee -a /etc/apt/sources.list

  sudo aptitude update
  sudo apt-get install --only-upgrade bash
)

# Update and Install Packages
(
  sudo aptitude upgrade -y
  sudo aptitude install -y \
      build-essential \
      ruby1.9.1 \
      git \
      vim \
      nginx-full \
      varnish \
      mc

  yes|sudo add-apt-repository ppa:nginx/stable
  sudo apt-get update
  sudo apt-get -y install nginx 
)

# Make binary files executable and copy ROOT files
(
  set +x
  echo "########################################"
  echo "# Copy ROOT files                      #"
  echo "########################################"
  set -x
  chmod a+x $PP/ROOT/usr/*bin/*
  chmod 0440 $PP/ROOT/etc/sudoers.d/flipit
  sudo rsync -rlptD --exclude='.git/' $PP/ROOT/ /
)


# Configure active user
(
  sudo useradd -d $USER_HOME -m $USER
  sudo chsh -s /bin/bash $USER
)

# Configure SSH
(
  sudo mkdir $USER_HOME/.ssh
  sudo cp $PP/ssh/* $USER_HOME/.ssh/
  sudo chown -R $USER:$USER $USER_HOME/.ssh
)

# Change timezone to AMS
(
  echo "######################################"
  echo "#     Changing timezone (AMS)        #"
  echo "######################################"
  sudo rm /etc/localtime
  sudo ln -sf /usr/share/zoneinfo/Europe/Amsterdam /etc/localtime
)

# Configure awslog agent
(
  echo "######################################"
  echo "#     Configuring AWS-log Agent      #"
  echo "######################################"
  AWSLOGS_DIR=/var/lib/awslogs
  sudo mkdir -p /var/lib/awslogs
  cd $AWSLOGS_DIR
  sudo wget https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py
  sudo chmod +x ./awslogs-agent-setup.py
  sudo ./awslogs-agent-setup.py -n -r eu-west-1 -c /etc/awslogs.conf
  sudo chmod a+x /etc/rc.local
)
