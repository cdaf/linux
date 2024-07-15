timeout(time: 6, unit: 'HOURS') {
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

      stage ('Prepare Workspace') {

        checkout scm

        sh '''
          cat Jenkinsfile
        '''
      }

      stage ('Regression Test Samples') {
        sh '''
          echo "Regression Test Samples"
          cd samples
          ./executeSamples.sh
          cd ..
        '''
      }


      stage ('Review Vagrant Settings') {

        sh '''
          cat Vagrantfile
          vagrant box list
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 18.04 LTS') {
        sh '''
          echo "Test the CDAF sample on Ubuntu 18.04 LTS"
          export OVERRIDE_IMAGE="cdaf/Ubuntu18"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 20.04 LTS') {
        sh '''
          echo "Test the CDAF sample on Ubuntu 20.04 LTS"
          vagrant destroy -f
          export OVERRIDE_IMAGE="cdaf/Ubuntu20"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 20.22 LTS') {
        sh '''
          echo "Test the CDAF sample on Ubuntu 20.22 LTS"
          vagrant destroy -f
          export OVERRIDE_IMAGE="cdaf/Ubuntu22"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu Latest') {
        sh '''
          echo "Test the CDAF sample on Ubuntu Latest"
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
        sh '''
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
        '''
      }
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
