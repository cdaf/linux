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

    } catch (e) {

      currentBuild.result = "FAILED"
      println currentBuild.result
      notifyFailed()
      throw e

    } finally {

      stage ('Uncondiational stage') {
        sh '''
          echo "Clean-up steps go here..."
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
