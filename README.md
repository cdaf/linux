Continuous Delivery Automation Framework for Linux and OSX
==========================================================

For usage details, see https://github.com/cdaf/linux/blob/master/automation/Readme.md

For framework details, see the readme in the automation folder.

For stable release packages see : http://cdaf.azurewebsites.net/

Desktop Testing
===============
This approach creates a desktop "build server" which allows the user to perform end-to-end continuous delivery testing.

Prerequisites
-------------
Oracle VirtualBox and Vagrant

Note: on Windows Server 2012 R2 need to manually install x86 (not 64 bit) C++ Redistributable.

# Known Issue Vagrant 1.8.1
    C:\HashiCorp\Vagrant\embedded\gems\gems\vagrant-1.8.1\plugins\providers\hyperv\scripts\get_vm_status.ps1 : Unable to find type

edit  get_vm_status.ps1  to catch exception type  Exception  instead of  Microsoft.HyperV.PowerShell.VirtualizationException 

Create Desktop Build Server
---------------------------

To create a desktop environment, navigate to the solution root and run:

    vagrant up

Continuous Delivery Testing
---------------------------

Vagrant provides a SSH connection natively for both Linux and Windows

    vagrant ssh buildserver
    cd C:\vagrant
	.\automation\cdEmulate.sh

Cleanup and Destroy
-------------------
If change made that need to be checked in, clean the workspace:

	.\automation\cdEmulate.bat clean

Once finished with the environment, destroy using:

    vagrant destroy -f