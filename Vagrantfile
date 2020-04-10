# -*- mode: ruby -*-
# vi: set ft=ruby :

if ENV['SCALE_FACTOR']
  SCALE_FACTOR = ENV['SCALE_FACTOR'].to_i
else
  SCALE_FACTOR = 1
end
if ENV['BASE_MEMORY']
  BASE_MEMORY = ENV['BASE_MEMORY'].to_i
else
  BASE_MEMORY = 2048
end

vRAM = BASE_MEMORY * SCALE_FACTOR
vCPU = SCALE_FACTOR

if rand(0..1) == 0
  box = 'cdaf/CentOSLVM'
else
  box = 'cdaf/UbuntuLVM'
end
puts "Random Box is #{box}" 

# This is provided to make scaling easier
if ENV['MAX_SERVER_TARGETS']
  puts "Deploy targets (MAX_SERVER_TARGETS) = #{ENV['MAX_SERVER_TARGETS']}" 
  MAX_SERVER_TARGETS = ENV['MAX_SERVER_TARGETS'].to_i
else
  MAX_SERVER_TARGETS = 1
end

Vagrant.configure(2) do |config|

  # Build Server connects to this host to perform deployment
  (1..MAX_SERVER_TARGETS).each do |i|
    config.vm.define "server-#{i}" do |server|
      server.vm.box = "#{box}"

      server.vm.provision 'shell', path: './automation/remote/capabilities.sh'

      # Deploy user has ownership of landing directory and trusts the build server via the public key
      server.vm.provision 'shell', path: './automation/provisioning/addUser.sh', args: 'deployer'
      server.vm.provision 'shell', path: './automation/provisioning/mkDirWithOwner.sh', args: '/opt/packages deployer'
      server.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'target'

      # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
      server.vm.provider 'virtualbox' do |virtualbox, override|
        virtualbox.memory = "#{vRAM}"
        virtualbox.cpus = "#{vCPU}"
        override.vm.network 'private_network', ip: "172.16.17.10#{i}"
        if ENV['SYNCED_FOLDER']
          override.vm.synced_folder "#{SYNCED_FOLDER}", "/.provision"
        end
      end

      # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up server-1 --provider hyperv
      server.vm.provider 'hyperv' do |hyperv, override|
        hyperv.memory = "#{vRAM}"
        hyperv.cpus = "#{vCPU}"
        override.vm.hostname  = "target-#{i}"
        hyperv.ip_address_timeout = 300 # 5 minutes, default is 2 minutes (120 seconds)
        if ENV['VAGRANT_SMB_USER']
          override.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: "#{ENV['VAGRANT_SMB_USER']}", smb_password: "#{ENV['VAGRANT_SMB_PASS']}"
        end
      end
    end
  end

  # Build Server, fills the role of the build agent and delivers to the host above
  config.vm.define 'build' do |build|  
    build.vm.box = "#{box}"
    build.vm.provision 'shell', path: './automation/remote/capabilities.sh'
    build.vm.provision 'shell', path: './automation/provisioning/setenv.sh', args: 'CDAF_DELIVERY VAGRANT'
    build.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'server' # Install Insecure preshared key for desktop testing
    build.vm.provision 'shell', path: './automation/provisioning/internalCA.sh'
    build.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', privileged: false
    build.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. buildonly', privileged: false
    build.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. packageonly', privileged: false
    build.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. cionly', privileged: false
    build.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. cdonly', privileged: false

    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    build.vm.provider 'virtualbox' do |virtualbox, override|
      virtualbox.memory = "#{vRAM}"
      virtualbox.cpus = "#{vCPU}"
      override.vm.network 'private_network', ip: '172.16.17.100'
      if ENV['SYNCED_FOLDER']
        override.vm.synced_folder "#{SYNCED_FOLDER}", "/.provision"
      end
      (1..MAX_SERVER_TARGETS).each do |s|
        override.vm.provision 'shell', path: './automation/provisioning/addHOSTS.sh', args: "172.16.17.10#{s} server-#{s}"
      end
    end

    # Microsoft Hyper-V does not support NAT or setting hostname. vagrant up build --provider hyperv
    build.vm.provider 'hyperv' do |hyperv, override|
      hyperv.vmname = "linux-build"
      hyperv.memory = "#{vRAM}"
      hyperv.cpus = "#{vCPU}"
      hyperv.ip_address_timeout = 300 # 5 minutes, default is 2 minutes (120 seconds)
      if ENV['VAGRANT_SMB_USER']
        override.vm.synced_folder ".", "/vagrant", type: "smb", smb_username: "#{ENV['VAGRANT_SMB_USER']}", smb_password: "#{ENV['VAGRANT_SMB_PASS']}"
      end
    end
  end

end
