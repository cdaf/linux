# Continuous Delivery Automation Framework (CDAF)

    Author  : Jules Clements
    Version : See CDAF.linux

This readme focuses on implementation details of the framework, see the overview documentation, see http://cdaf.io/about

# Provisioning

When using for the first time, the users workstation needs to be prepared by provisioning the following features

- Package Compression
- Loopback Connection
- Landing Folder

# Solution Driver

The following files control solution level functionality.

    CDAF.linux : used by the CD emulator to determine the automation root directory  
    CDAF.solution : optional file to identify a directory as the automation solution directory, if contains property solutionName, this will be used in the emulator

Basic driver files (introduced 1.7.8):

	properties.cm
	storeFor
	tasksRun.tsk

Properties and definition files support comments, prefixed with # character.

## Execution Engine

To alleviate the burden of argument passing, exception handling and logging, the execution engine has been provided. The execution engine will essentially execute the native interpretive language (PowerShell or bash), line by line, but each execution will be tested for exceptions (trivial in bash, significantly more complex in PowerShell) and, with careful usage, the driver files (.tsk) can be used on Windows workstations, while target Linux servers for Continuous Delivery. To provide translated runtime, the following keywords are supported

| Keyword | Description                       | Example                         |
| --------|-----------------------------------|---------------------------------|
| ASSIGN  | set a variable                    | ASSIGN $test="Hello World"      |
| CMPRSS  | Compress directory to file        | CMPRSS packageName dirName      |
| DCMPRS  | Decompress package file           | DCMPRS packageName              |
| DECRYP  | decrypt using private_key.pem     | DECRYP crypt/encrypt.dat        |
|         | decrypt using AES key             | DECRYP crypt/encrypt.dat $key   |
| DETOKN  | Detokenise file with target prop  | DETOKN token.yml                |
|         | Detokenise with specific file     | DETOKN token.yml PROP_FILE      |
|         | Detokenise with encrypted file    | DETOKN token.yml crypt/FIL $key |
| EXCREM  | Execute command                   | EXCREM hostname                 |
|         | Execute script                    | EXCREM ./capabilities.sh        |
| EXITIF  | Exit normally if argument set     | EXITIF $ACTION                  |
|         | Exit normally if set to value     | EXITIF $ACTION clean            |
| INVOKE  | call a custom script              | INVOKE ./script "Hello"         |
| MAKDIR  | Create a directory and path (opt) | MAKDIR directory/and/path       |
| PROPLD  | Load properties as variables      | PROPLD prop.file                |
| REMOVE  | Delete files, including wildcard  | REMOVE *.war                    |
| REPLAC  | Replace token in file   		  | REPLAC fileName %token% $value  |
| VECOPY  | Verbose copy					  | VECOPY *.war                    |

Runtime variables, automatically set

| Variable         | Description                       |
| -----------------|-----------------------------------|
|  $TMPDIR         | Automatically set to the temp dir |

## Build and Package (once)

buildProjects : optional, all directories containing build.sh or build.tsk will be processed

Linear Deploy requires properties file for workstation (default is DEV) to be a match (not partial match as per repeatable local and remote processes). transform.sh utility can be used to load all defined properties.

Package: (files maybe empty or non-existent)

	package.tsk : optional pre-package tasks definition (0.7.2)
	wrap.tsk : optional post-package tasks definition (0.8.2)
	storeForLocal
	storeForRemote

The package (.gz) file is generated from the contents of the TasksRemote directory, all scripts contained in the /remote folder are copied and files file/directories listed in storeForRemote (maybe empty).

All scripts contained in the /local folder are copied to the TasksLocal directory, along with the files/directories listed in storeForLocal file (maybe empty). A package file of local tasks can also be created by setting zipLocal in the CDAF.solution file, the value set will be used in the package name itself.

## Deploy (many)

Default task definitions, these can be overridden using deployScriptOverride or deployTaskOverride (a space separated list is supported) in properties file

	tasksRunLocal.tsk
	tasksRunRemote.tsk

For an empty solution, the automation/cdEmulate.sh should run successfully and simply create a zip file with the remote deployment wrapper and helper scripts. Transform.ps1 utility can be used to load all defined properties or detokenise a settings file.

Optional sub-directories of /solution

	/propertiesForLocalTasks
	/propertiesForRemoteTasks

Encrypted files (for passwords)

	/cryptRemoteRemote
	/cryptRemoteLocal

Custom elements, i,.e. deployScriptOverride and deployTaskOverride scripts

	/custom
	/customRemote
	/customLocal

# Continuous Delivery Emulation

To support Continuous Delivery, the automation of Deployment is required, to automate deployment, the automation of packaging is required, and to automate packaging, the automation of build is required.

## Build and Package  

To produce a self-extracting shell script for deployment, set artifactPrefix in CDAF.solution

### Automated Build

If it exists, each project in the Project.list file is processed, in order (to support cross project dependencies), if the file does not exist, all project directores are processed, alphabetically.
Each project directory is entered and the build.sh script is executed. Each build script is expected to support build and clean actions.

### Automated Packaging

The artifacts from each project are copied to the root workspace, along with local and remote support scripts. The remote support scripts and include with the build artifacts in a single zip file, while the local scripts and retained in a directory (DeployLocal). It is the package.sh script which manages this, leaving only artifacts that are to be retained in the workspace root.

## Container Builds

This functionality allows for multiple build requirements (which maybe mutually exclusive at a system level) to be combined on a single host. It is expected that the build dependencies are defined in code (bootstrapAgent.sh) and not image based. This exploits the disk layer mechanisms of Docker to only rebuild the agent image if a change in definition occurs and not every time a build is perform.

### Applying a Container Build

 - Copy the Dockerfile from the GitHub samples directory to the root of your solution
 - Copy the bootstrapAgent.sh from the GitHub samples to your solution folder
 - uncomment the containerBuild line from the CDAF.solution in your solution folder

Alter the bootstrapAgent.sh to fulfill the build dependencies. Note: if you have a Vagrantfile for your solution, ideally the same bootstrap would be used for both Vagrant and Container Build implementations:

    override.vm.provision 'shell', path: './automation-solution/bootstrapAgent.sh'

## Remote Tasks

The automation of deployment uses ssh to create a remote connection to each target in the local/properties files for the environment symbol, i.e. CD, ST, etc. The zip file (Package) is copied to the target host and extracted, the properties file for that target is also copied and then the entry script (deploy.sh) is called.

## Local Tasks

Executed from the current host, i.e. the build server or agent, and may connect to remove hosts through direct protocols, i.e. WebDAV, ODBC/JDBC, HTTP(S), etc.
