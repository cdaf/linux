# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  # Target host running Ubuntu 14.04 LTS Server
  config.vm.define 'target' do |target|
    # Oracle VirtualBox
    target.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.101'
      override.vm.hostname = 'target.skynet'
      override.vm.box = 'ubuntu/trusty64'
      override.vm.network 'forwarded_port', guest: 22, host: 10022
      override.vm.network 'forwarded_port', guest: 80, host: 10080
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up target --provider hyperv
    target.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'serveit/centos-7'
    end
    # Provisioninng is the same, regardless of provider
    target.vm.provision 'shell', path: 'automation/provisioning/deployer.sh', args: 'target'
  end
  
  # Build host running Ubuntu 14.04 LTS Server
  config.vm.define 'buildserver' do |buildserver|  
    # Oracle VirtualBox
    buildserver.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.106'
      override.vm.hostname = 'buildserver.skynet'
      override.vm.box = 'ubuntu/trusty64'
      override.vm.network 'forwarded_port', guest: 22, host: 20022
    end
    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up buildserver --provider hyperv
    buildserver.vm.provider 'hyperv' do |hyperv, override|
      override.vm.box = 'serveit/centos-7'
    end
    # Provisioninng is the same, regardless of provider
    buildserver.vm.provision 'shell', path: 'automation/provisioning/setenv.sh', args: 'environmentDelivery VAGRANT'
    buildserver.vm.provision 'shell', path: 'automation/provisioning/deployer.sh'
    buildserver.vm.provision 'shell', path: 'automation/provisioning/CDAF.sh'
  end

end
