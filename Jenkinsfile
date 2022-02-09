timeout(time: 60, unit: 'MINUTES') {
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

      stage ('Test the CDAF sample on Ubuntu 16.04 LTS') {

        checkout scm
    
        sh "cat Jenkinsfile"
        sh "cat Vagrantfile"
        sh "cat automation/CDAF.linux | grep productVersion"

        sh "if [ -d ./.vagrant ]; then vagrant destroy -f; fi"
        sh "vagrant box list"
        sh "vagrant up"
      }

      stage ('Test the CDAF sample on Ubuntu 16.04 LTS') {
        sh '''
          vagrant destroy -f
          export OVERRIDE_IMAGE="cdaf/UbuntuLVM"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 18.04 LTS') {
        sh '''
          vagrant destroy -f
          export OVERRIDE_IMAGE="cdaf/UbuntuLVM"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 20.04 LTS') {
        sh '''
          vagrant destroy -f
          export OVERRIDE_IMAGE="cdaf/UbuntuLVM"
          vagrant up
        '''
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
      recipientProviders: [[$class: 'DevelopersRecipientProvider']],
      subject: "Linux FAILURE [${env.JOB_NAME}] Build [${env.BUILD_NUMBER}]",
      body: "Check console output at ${env.BUILD_URL}"
    )

    if (env.DEFAULT_NOTIFICATION) {
      emailext (
        to: "${env.DEFAULT_NOTIFICATION}",
        subject: "Linux FAILURE [${env.JOB_NAME}] Build [${env.BUILD_NUMBER}]",
        body: "Check console output at ${env.BUILD_URL}"
      )
    }

  }
}