# Continuous Delivery Automation Framework for Linux and OSX

For usage details, see https://github.com/cdaf/linux/blob/master/automation/Readme.md

For framework details, see the readme in the automation folder. For stable release packages see : http://cdaf.io

To download and extract this repository

    curl -o linux-master.zip https://codeload.github.com/cdaf/linux/zip/master
    unzip linux-master.zip

# Desktop Testing

This approach creates a desktop "build server" which allows the user to perform end-to-end continuous delivery testing.

##Prerequisites

Oracle VirtualBox and Vagrant

Note: on Windows Server 2012 R2 need to manually install x86 (not 64 bit) C++ Redistributable.

# Create Desktop Build Server

To create a desktop environment, navigate to the solution root and run:

    vagrant up

# Continuous Delivery Testing

Once the environment is running access the build server an execute the CD emulation. Note: On a Windows host bash tools are recommended to provide native SSH access.

    vagrant ssh build
    cd /vagrant
	./automation/cdEmulate.sh

# Cleanup and Destroy

If change made that need to be checked in, clean the workspace:

	.\automation\cdEmulate.sh clean

Once finished with the environment, destroy using:

    vagrant destroy -f