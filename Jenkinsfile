pipeline {
    agent any
    triggers {
        cron(env.BRANCH_NAME == 'master' ? 'H 0 * * *' : '')
    }
    options {
        timestamps()
        timeout(time: 1, unit: 'HOURS')
    }
    stages {
        stage('checkout') {
            when { branch 'master' }
            steps {
                checkout scm
            }
        }
        stage('bootstrap') {
            when { branch 'master' }
            steps {
                sh './bootstrap.sh'
            }
        }
        stage('test') {
            when { branch 'master' }
            steps {
                dir('SyncIntegrationTests') {
                    sh 'pipenv install'
                    sh 'pipenv check -i 37752 // Ignoring vulnerability due to https://github.com/pypa/pipenv/issues/4147'
                    sh 'pipenv run pytest ' +
                        '--color=yes ' +
                        '--junit-xml=results/junit.xml ' +
                        '--html=results/index.html'
                }
            }
        }
    }
    post {
        always {
             script {
                 if (env.BRANCH_NAME == 'master') {
                 archiveArtifacts 'SyncIntegrationTests/results/*'
                 junit 'SyncIntegrationTests/results/*.xml'
                 publishHTML(target: [
                     allowMissing: false,
                     alwaysLinkToLastBuild: true,
                     keepAll: true,
                     reportDir: 'SyncIntegrationTests/results',
                     reportFiles: 'index.html',
                     reportName: 'HTML Report'])
                 }
             }
        }

        failure {
            script {
                if (env.BRANCH_NAME == 'master') {
                    slackSend(
                        color: 'danger',
                        message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
                }
            }
        }
        fixed {
            slackSend(
                color: 'good',
                message: "FIXED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}
