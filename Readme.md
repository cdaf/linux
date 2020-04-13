[![License: LGPL v3](https://img.shields.io/badge/License-LGPL%20v3-blue.svg)](https://www.gnu.org/licenses/lgpl-3.0)
[![cdaf version](automation/badge.svg)](http://cdaf.io)

# Continuous Delivery Automation Framework for Linux and OSX

The automation framework provides a "lowest common denominator" approach, where CI & CD can be executed on the desktop as they would be in an orchestration tool (Azure DevOps, GitLab, Bamboo, TeamCity, Jenkins, etc). For stable release packages see : http://cdaf.io

## Why use CDAF

To provide a consistent approach to Continuous Delivery and leverage the efforts of others to provide greater reusability and easier problem determination. CDAF will provide the building blocks for common tasks, with rich logging and exception handling. The CDAf provides toolset configuration guidance, keeping the actions loosely coupled with the toolset, to allow visibility and traceability through source control rather than direct changes.

## Environment Variables

Emulation and execution behaviour can be controlled by the following environment variables

### Emulation

 - CDAF_DELIVERY The default target environment for cdEmulate.sh, uses LINUX if not set
 - CDAF_BRANCH_NAME Allows the specification of a branch name if CI behaviour differs by branch, i.e. master vs. feature branches 
 
### Execution

 - CDAF_DOCKER_REQUIRED containerBuild will attempt to start Docker if not running and will fail if it cannot, rather than falling back to native execution

# Desktop Testing

This approach creates a desktop "build server" which allows the user to perform end-to-end continuous delivery testing.

## Prerequisites

Vagrant and Oracle VirtualBox or Microsoft Hyper-V

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
