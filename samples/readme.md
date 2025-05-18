# CDAF Samples

> following is not applicable to Windows Subsystem for Linux (WSL).

To execute samples that perform remote tasks, provision a loopback connection to your localhost. Replace Password! appropriately.

```
../provisioning/base.sh openssh-server
../provisioning/addUser.sh deployer deployer no Password!
sudo mkdir /opt/packages/
sudo chown deployer /opt/packages/
../provisioning/agent.sh deployer@localhost
```

To run docker samples

    ../provisioning/installDocker.sh

To run this readme as a script, use

    ./runReadme.sh

to execute all samples

    ./executeSamples.sh