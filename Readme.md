[![cdaf version](automation/badge.svg)](http://cdaf.io)

# Continuous Delivery Automation Framework for Linux and OSX

The automation framework provides a "lowest common denominator" approach, where underlying action are implemented in bash.

This automation framework functionality is based on user defined solution files. By default the /solution folder stores these files, however, a stand alone folder, in the solution root is supported, identified by the CDAF.solution file in the root.

## Why use CDAF

To provide a consistent approach to Continuous Delivery and leverage the efforts of others to provide greater reusability and easier problem determination. CDAF will provide the building blocks for common tasks, with rich logging and exeception handling. The CDAf provides toolset configuration guidance, keeping the actions loosely coupled with the toolset, to allow visibilty and traceability through source control rather than direct changes.

## Why not have a shared folder for CDAF on the system

CDAF principles are to have a minimum level of system dependency. By having solution specific copies each solution can use differing versions of CDAF, and once a solution is upgraded, that upgrade will be propogated to all uses (at next update/pull/get) where a system provisioned solution will requrie all users to update to the same version, even if their current solution has not been tested for this system wide change.

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