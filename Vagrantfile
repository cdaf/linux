# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

# As at 13-Mar-2016 Vagrant CentOS 7 inoperable on Windows
# Had to use a 3rd party box, to download and add use this command before vagrant up
# vagrant box add CentOS7_holms https://github.com/holms/vagrant-centos7-box/releases/download/7.1.1503.001/CentOS-7.1.1503-x86_64-netboot.box

  # Docker host (DL) running Ubuntu 14.04 LTS Server
  config.vm.define 'ubuntu' do |ubuntu|
    ubuntu.vm.network 'private_network', ip: '172.16.17.101'
    ubuntu.vm.hostname = 'ubuntu.skynet'
    
    ubuntu.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.box = 'ubuntu/trusty64'
      override.vm.network 'forwarded_port', guest: 22, host: 10022
      override.vm.network 'forwarded_port', guest: 80, host: 10080
    end
    
    ubuntu.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'hashicorp/precise64'
      override.vm.network 'forwarded_port', guest: 22, host: 10022
      override.vm.network 'forwarded_port', guest: 80, host: 10080
    end
    
    ubuntu.vm.provision 'shell', path: 'automation/provisioning/deployer.sh', args: 'target'
  end
  
  # Build host (COJ) running CentOS 7
  config.vm.define 'buildserver' do |buildserver|
    buildserver.vm.network 'private_network', ip: '172.16.17.106'
    buildserver.vm.hostname = 'buildserver.skynet'
    
    buildserver.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.box = "ubuntu/trusty64"
      override.vm.network 'forwarded_port', guest: 22, host: 20022
    end
    
    buildserver.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'hashicorp/precise64'
      override.vm.network 'forwarded_port', guest: 22, host: 20022
    end
    
    buildserver.vm.provision 'shell', path: 'automation/provisioning/setenv.sh', args: 'environmentDelivery VAGRANT'
    buildserver.vm.provision 'shell', path: 'automation/provisioning/deployer.sh'
    buildserver.vm.provision "shell", path: "automation/provisioning/setenv.sh", args: "environmentDelivery VAGRANT"
    buildserver.vm.provision 'shell', path: 'automation/provisioning/CDAF.sh'
  end

end
