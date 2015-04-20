Automated build and Deploy
==========================

Author  : Jules Clements
Version : 20-Apr-2015
Version : 0.8.0

Framework Overview
==================

The automation framework provides a "lowest common denominator" approach, where underlying action are implemented in bash.

This automation framework functionality is based user defined solution files. By default the /solution folder stores these files, however, a stand alone folder, in the solution root is supported, by including the following file

CDAF.solution : optional file to identify a directory as the automation solution directory

Properties and definition files support comments, prefixed with # character.

Build and Package (once)
------------------------
buildProjects : optional, all directories containing build.sh or build.tsk will be processed

Linear Deploy requires properties file for workstation (default is DEV) to be a match (not partial match as per repeatable local and remote processes). transform.sh utility can be used to load all defined properties.

Package: (files maybe empty or non-existent)

	package.tsk : optional pre-package tasks definition
	storeForLocal
	storeForRemote

supported arguments are -Recurse (copy all contents of folder and retain path as subdirectory) and -Flat (copy directory without path)

Note: during the packaging process, helper scripts contained in the /remote folder are copied to the TasksLocal folder.

Execute (many)
--------------
Default task definitions, these can be overridden using deployScriptOverride= in properties file

	tasksRunLocal.tsk
	tasksRunRemote.tsk

For an empty solution, the automation/cdEmulate.sh should run successfully and simply create a zip file with the remote deployment wrapper and helper scripts. Transform.ps1 utility can be used to load all defined properties or detokenise a settings file.

Optional sub-directories of /solution

	/propertiesForLocalTasks
	/propertiesForRemoteTasks

Encrypted files (for passwords)

	/cryptRemoteRemote
	/cryptRemoteLocal

Custom elements, i,.e. deployScriptOverride scripts

	/customRemote
	/customLocal

Continuous Delivery Emulation
=============================

To support Continuous Delivery, the automation of Deployment is required, to automate deployment, the automation of packaging is required, and to automate packaging, the automation of build is required.  

Automated Build
---------------

If it exists, each project in the Project.list file is processed, in order (to support cross project dependencies), if the file does not exist, all project directores are processed, alphabetically.
Each project directory is entered and the build.sh script is executed. Each build script is expected to support build and clean actions.

Automated Packaging
-------------------

The artifacts from each project are copied to the root workspace, along with local and remote support scripts. The remote support scripts and include with the build artifacts in a single zip file, while the local scripts and retained in a directory (DeployLocal). It is the package.sh script which manages this, leaving only artifacts that are to be retained in the workspace root.

Remote Tasks
------------

The automation of deployment uses ssh to create a remote connection to each target in the local/properties files for the environment symbol, i.e. CD, ST, etc. The zip file (Package) is copied to the target host and extracted, the properties file for that target is also copied and then the entry script (deploy.sh) is called.

Local Tasks
-----------

Executed from the current host, i.e. the build server or agent, and may connect to remove hosts through direct protocols, i.e. WebDAV, ODBC/JDBC, HTTP(S), etc.

Automated Function Tests
------------------------

Currently PhantomJS is used to perform the headless function testing, although an example of using Firefox with Xvfb is also included but not used.