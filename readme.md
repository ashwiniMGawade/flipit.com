# Flipit development box

## To get the application running on your local system for UNIX systems
- Go to the folder where you want the files to be placed. For example `cd ~/Sites`
- `git clone git@bitbucket.org:webflight/flipit.com.git`
- `cd flipit.com/`
- `git submodule update --init --recursive`
- Go to your host file and add the following: `192.168.56.102 dev.kortingscode.nl`
- Go to your host file and add the following: `192.168.56.102 dev.flipit.com`
- `vagrant up`
- Setup your application.ini in flipit_application/application/config/application.ini
- [dev.kortingscode.nl](http://dev.kortingscode.nl)
- [dev.flipit.com](http://dev.flipit.com)

## Restore the DB with a fresh copy
- While the VM is running go inside the VM `vagrant ssh`
- `bash /var/scripts/reset_dbs.sh`

## VM usage
- To start the VM: `vagrant up`
- To get in the VM: `vagrant ssh`
- To stop the VM for the day: `vagrant suspend`
- To remove the VM from your system: `vagrant destroy` (THIS WILL DELETE YOUR DB)
- For more info see [Vagrantup.com](https://docs.vagrantup.com/v2/getting-started/teardown.html)

## Using MailCatcher
- Load [http://192.168.56.102:1080/](http://192.168.56.102:1080/) in your browser to view the MailCatcher interface

## What is MailCatcher?
Check out the [MailCatcher](http://mailcatcher.me/) homepage, but the short description is that it catches email being sent and let's you view it via a web interface (port 1080 on the VM). This way you don't have to actually send email through the internet and wait for it to be delivered, etc. You can check the queue with your browser easily and clear it whenever you'd like. This also means that you could make your VM send thousands of emails (intentionally or unintentionally) and easily see if they would have been delivered.

## Features
- VM Description
	- 1GB RAM
	- Ubuntu 14.04 LTS (trusty)
	- Apache w/ mod_rewrite
	- MySQL
	- PHP 5.5
	- OPCache
	- Memcached
	- [MailCatcher](http://mailcatcher.me/)
	- PhpMyAdmin [http://192.168.56.102/phpmyadmin/](http://192.168.56.102/phpmyadmin/)
	- MySQL root credentials are for the user `root` and password `root`

## Reference
This build has been inspired by numerous vagrant setups:

- https://github.com/mwalters/simple-vagrant-lamp/blob/master/bootstrap.sh
- https://github.com/matthewbdaly/vagrant-php-dev-boilerplate/blob/master/bootstrap.sh

## To-Do
- Create a DB SYNC cron
- Create and IMAGE SYNC cron
- Setup DB script check if user and DB exist, else move on