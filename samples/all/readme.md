# All CDAF Core Features

To avoid execution of Remote Tasks

    export CDAF_DELIVERY='WSL'

To executes Remote Tasks, configure remote loop-back access to the localhost.

    ../../provisioning/addUser.sh deployer deployer no Password!
    ../../provisioning/agent.sh deployer@localhost
    sudo mkdir /opt/packages
    sudo chown deployer -R /opt/packages
