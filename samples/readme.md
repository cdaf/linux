# CDAF Samples

To execute samples that perform remote tasks, provision a loopback connection to your localhost. Replace Password! appropriately.

```
../automation/provisioning/addUser.sh deployer deployer no Password!
../automation/provisioning/agent.sh deployer@localhost
```
 
 To run this readme as a script, use

    ./executeReadme.sh