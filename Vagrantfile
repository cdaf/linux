# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.

# Different VM images can be used by changing this variable, for example to use Windows Server 2016 with GUI
# $env:OVERRIDE_IMAGE = 'cdaf/CentOSLVM'
if ENV['OVERRIDE_IMAGE']
  vagrantBox = ENV['OVERRIDE_IMAGE']
else
  vagrantBox = 'cdaf/UbuntuLVM'
end

# If this environment variable is set, RAM and CPU allocations for virtual machines are increase by this factor, so must be an integer
# ./automation/provisioning/setenv.sh SCALE_FACTOR 2
if ENV['SCALE_FACTOR']
  scale = ENV['SCALE_FACTOR'].to_i
else
  scale = 1
end
if ENV['BASE_MEMORY']
  baseRAM = ENV['BASE_MEMORY'].to_i
else
  baseRAM = 1024
end

vRAM = baseRAM * scale
vCPU = scale

# If this environment variable is set, then the location defined will be used for media
# ./automation/provisioning/setenv.sh SYNCED_FOLDER /opt/.provision
if ENV['SYNCED_FOLDER']
  synchedFolder = ENV['SYNCED_FOLDER']
end

Vagrant.configure(2) do |config|

  # Build Server connects to this host to perform deployment
  config.vm.define 'target' do |target|
    target.vm.box = "#{vagrantBox}"

    target.vm.provision 'shell', path: './automation/remote/capabilities.sh'
    
    # Deploy user has ownership of landing directory and trusts the build server via the public key
    target.vm.provision 'shell', path: './automation/provisioning/addUser.sh', args: 'deployer'
    target.vm.provision 'shell', path: './automation/provisioning/mkDirWithOwner.sh', args: '/opt/packages deployer'
    target.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'target'

    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    target.vm.provider 'virtualbox' do |virtualbox, override|
      virtualbox.name = 'linux-target'
      virtualbox.memory = "#{vRAM}"
      virtualbox.cpus = "#{vCPU}"
      override.vm.network 'private_network', ip: '172.16.17.103'
      if synchedFolder
        override.vm.synced_folder "#{synchedFolder}", "/.provision"
      end
    end

    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up target --provider hyperv
    target.vm.provider 'hyperv' do |hyperv, override|
      hyperv.vmname = "linux-target"
      hyperv.memory = "#{vRAM}"
      hyperv.cpus = "#{vCPU}"
      hyperv.ip_address_timeout = 300 # 5 minutes, default is 2 minutes (120 seconds)
    end
  end
  
  # Build Server, fills the role of the build agent and delivers to the host above
  config.vm.define 'build' do |build|  
    build.vm.box = "#{vagrantBox}"
    build.vm.provision 'shell', path: './automation/remote/capabilities.sh'

    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    build.vm.provider 'virtualbox' do |virtualbox, override|
      virtualbox.name = 'linux-build'
      virtualbox.memory = "#{vRAM}"
      virtualbox.cpus = "#{vCPU}"
      override.vm.network 'private_network', ip: '172.16.17.101'
      if synchedFolder
        override.vm.synced_folder "#{synchedFolder}", "/.provision"
      end
      override.vm.provision 'shell', path: './automation/provisioning/addHOSTS.sh', args: '172.16.17.103 target.sky.net'
      override.vm.provision 'shell', path: './automation/provisioning/setenv.sh', args: 'environmentDelivery VAGRANT'
      override.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'server' # Install Insecure preshared key for desktop testing
      override.vm.provision 'shell', path: './automation/provisioning/internalCA.sh'
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. buildonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. packageonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. cionly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. cdonly', privileged: false
    end

    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up build --provider hyperv
    build.vm.provider 'hyperv' do |hyperv, override|
      hyperv.vmname = "linux-build"
      hyperv.memory = "#{vRAM}"
      hyperv.cpus = "#{vCPU}"
      hyperv.ip_address_timeout = 300 # 5 minutes, default is 2 minutes (120 seconds)
    end
  end

end
