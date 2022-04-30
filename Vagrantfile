# -*- mode: ruby -*-
# vi: set ft=ruby :

if ENV['SCALE_FACTOR']
  SCALE_FACTOR = ENV['SCALE_FACTOR'].to_i
else
  SCALE_FACTOR = 1
end

if ENV['OVERRIDE_IMAGE']
  OVERRIDE_IMAGE = ENV['OVERRIDE_IMAGE']
  puts "OVERRIDE_IMAGE specified, using box #{OVERRIDE_IMAGE}" 
else
  OVERRIDE_IMAGE = 'cdaf/Ubuntu18'
  puts "OVERRIDE_IMAGE not specified, use default box #{OVERRIDE_IMAGE}" 
end

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
    config.vm.define "linux-#{i}" do |linux|
      linux.vm.box = "#{OVERRIDE_IMAGE}"

      linux.vm.provision 'shell', path: './automation/remote/capabilities.sh'

      # Deploy user has ownership of landing directory and trusts the build server via the public key
      linux.vm.provision 'shell', path: './automation/provisioning/addUser.sh', args: 'deployer'
      linux.vm.provision 'shell', path: './automation/provisioning/mkDirWithOwner.sh', args: '/opt/packages deployer'
      linux.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'target'

      # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
      linux.vm.provider 'virtualbox' do |virtualbox, override|
        override.vm.network 'private_network', ip: "172.16.17.10#{i}"
        override.vm.synced_folder ".", "/vagrant", disabled: true
        if ENV['SYNCED_FOLDER']
          override.vm.synced_folder "#{ENV['SYNCED_FOLDER']}", "/.provision"
        end
      end

      # vagrant up linux-1 --provider hyperv
      linux.vm.provider 'hyperv' do |hyperv, override|
        override.vm.hostname  = "linux-#{i}"
        override.vm.synced_folder ".", "/vagrant", disabled: true
        if ENV['SYNCED_FOLDER']
          override.vm.synced_folder "#{ENV['SYNCED_FOLDER']}", "/.provision", smb_username: "#{ENV['VAGRANT_SMB_USER']}", smb_password: "#{ENV['VAGRANT_SMB_PASS']}", type: "smb", mount_options: ["vers=2.1"]
        end
      end
    end
  end

  # Build Server, fills the role of the build agent and delivers to the host above
  config.vm.define 'build' do |build|  
    build.vm.box = "#{OVERRIDE_IMAGE}"
    build.vm.provision 'shell', path: './automation/remote/capabilities.sh'
    build.vm.provision 'shell', path: './automation/provisioning/setenv.sh', args: 'CDAF_DELIVERY VAGRANT'
    build.vm.provision 'shell', path: './automation/provisioning/deployer.sh', args: 'server' # Install Insecure preshared key for desktop testing
    build.vm.provision 'shell', path: './automation/provisioning/internalCA.sh'

    # Oracle VirtualBox with private NAT has insecure deployer keys for desktop testing
    build.vm.provider 'virtualbox' do |virtualbox, override|
      override.vm.network 'private_network', ip: '172.16.17.100'
      (1..MAX_SERVER_TARGETS).each do |s|
        override.vm.provision 'shell', path: './automation/provisioning/addHOSTS.sh', args: "172.16.17.10#{s} linux-#{s}.mshome.net"
      end
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ buildonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ packageonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ cionly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ cdonly', privileged: false
    end

    # vagrant up build --provider hyperv
    build.vm.provider 'hyperv' do |hyperv, override|
      override.vm.hostname  = 'build'
      override.vm.synced_folder ".", "/vagrant", smb_username: "#{ENV['VAGRANT_SMB_USER']}", smb_password: "#{ENV['VAGRANT_SMB_PASS']}", type: "smb", mount_options: ["vers=2.1"]
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ buildonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ packageonly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ cionly', privileged: false
      override.vm.provision 'shell', path: './automation/provisioning/CDAF.sh', args: '. /vagrant/automation/ cdonly', privileged: false
    end
  end

end
