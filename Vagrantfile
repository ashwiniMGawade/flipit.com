## To-Do
# Integrate mailcaster

Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/trusty64"
    config.vm.box_url = "https://vagrantcloud.com/ubuntu/trusty64"
    config.vm.network :private_network, ip: "192.168.56.102"
    config.vm.network :forwarded_port, guest: 22, host: 9965

    config.vm.provider :virtualbox do |v|
        v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        v.customize ["modifyvm", :id, "--memory", 1024]
        v.customize ["modifyvm", :id, "--name", "kc-flipit"]
    end

    config.vm.synced_folder "./flipit_application", "/var/www/flipit_application", create: true, type: "nfs"
    config.vm.synced_folder "VM/sqldump", "/var/sqldump", create: true
    config.vm.synced_folder "VM/scripts", "/var/scripts", create: true
    config.vm.synced_folder "VM/custom_config_files", "/var/custom_config_files", create: true
    config.vm.synced_folder "VM/tasks", "/var/tasks", create: true


    config.vm.provision :shell, :path => "VM/bootstrap.sh"
    config.vm.provision :shell, run: "always", :path => "VM/load.sh"

end