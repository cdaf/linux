node {

  properties(
    [
      [
        $class: 'BuildDiscarderProperty',
        strategy: [$class: 'LogRotator', numToKeepStr: '10']
      ],
        pipelineTriggers([cron('45 23 * * *')]),
    ]
  )

  try {

    stage ('Test the CDAF sample Vagrantfile') {

      checkout scm
  
      sh "cat Jenkinsfile"
      sh "cat Vagrantfile"
      sh "cat automation/CDAF.linux | grep productVersion"

      sh "if [ -d ./.vagrant ]; then vagrant destroy -f; fi"
      sh "vagrant box list"
      sh "vagrant up"
    }
  
  } catch (e) {
  
    currentBuild.result = "FAILED"
    println currentBuild.result
    notifyFailed()
    throw e

  } finally {
  
    stage ('Destroy VMs and Discard sample vagrantfile') {
      sh "if [ -d ./.vagrant ]; then vagrant destroy -f; fi"
    }
  }
}

def notifyFailed() {

  emailext (
    to: "jenkins@SP1.hdc.webhop.net",
    subject: "Jenkins Job [${env.JOB_NAME}] Build [${env.BUILD_NUMBER}] failure",
    body: "Check console output at ${env.BUILD_URL}"
  )

  emailext (
    recipientProviders: [[$class: 'DevelopersRecipientProvider']],
    subject: "Jenkins Job [${env.JOB_NAME}] Build [${env.BUILD_NUMBER}] failure",
    body: "Check console output at ${env.BUILD_URL}"
  )
}
