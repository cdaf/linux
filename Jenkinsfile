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
    
        sh '''
          cat Jenkinsfile
          cat Vagrantfile
          cat automation/CDAF.linux | grep productVersion

          echo "Copy solution to workspace"
          rm -rf solution
          cp -r automation/solution solution
          if [ -f solution/CDAF.solution ]; then
            cat solution/CDAF.solution
          else
            exit 8833
          fi

          vagrant box list
        '''
      }

      stage ('Test the CDAF sample on CentOS 7') {
        sh '''
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
          export OVERRIDE_IMAGE="cdaf/CentOSLVM"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 16.04 LTS') {
        sh '''
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
          export OVERRIDE_IMAGE="cdaf/UbuntuLVM"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 18.04 LTS') {
        sh '''
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
          export OVERRIDE_IMAGE="cdaf/Ubuntu18"
          vagrant up
        '''
      }

      stage ('Test the CDAF sample on Ubuntu 20.04 LTS') {
        sh '''
          if [ -d ./.vagrant ]; then
            vagrant destroy -f
          fi
          export OVERRIDE_IMAGE="cdaf/Ubuntu20"
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
