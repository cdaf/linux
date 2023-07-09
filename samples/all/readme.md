# All CDAF Core Features

To avoid execution of Remote Tasks

    export CDAF_DELIVERY='WSL'

To executs Remote Tasks, configure remote loop-back access to teh localhost.

    ../../automation/provisioning/addUser.sh deployer deployer no Password!
    ../../automation/provisioning/agent.sh deployer@localhost
    sudo mkdir /opt/packages
    sudo chown deployer -R /opt/packages
