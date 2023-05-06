# CDAF Samples

To execute samples that perform remote tasks, provision a loopback connection to your localhost. Replace Password! appropriately.

```
../automation/provisioning/addUser.sh deployer deployer no Password!
../automation/provisioning/agent.sh deployer@localhost
sudo mkdir /opt/packages/
sudo chown deployer /opt/packages/
```
 
 To run this readme as a script, use

    ./executeReadme.sh