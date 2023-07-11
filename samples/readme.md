# CDAF Samples

To execute samples that perform remote tasks, provision a loopback connection to your localhost. Replace Password! appropriately.

```
../automation/provisioning/base.sh openssh-server
../automation/provisioning/addUser.sh deployer deployer no Password!
sudo mkdir /opt/packages/
sudo chown deployer /opt/packages/
../automation/provisioning/agent.sh deployer@localhost
```

To run docker samples

    ../automation/provisioning/installDocker.sh
    sudo usermod -a -G docker $(whoami)
    sudo shutdown -r now

To run this readme as a script, use

    ./runReadme.sh

to execute all samples

    ./executeSamples.sh