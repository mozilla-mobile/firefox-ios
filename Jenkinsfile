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
            steps {
                checkout scm
            }
        }
        stage('bootstrap') {
            steps {
                sh './bootstrap.sh'
            }
        }
        stage('test') {
            steps {
                dir('SyncIntegrationTests') {
                    sh 'pipenv install'
                    sh 'pipenv check -i 36351' // Ignoring vulnerability due to https://github.com/pyupio/safety-db/issues/2272
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
        failure {
            slackSend(
				if (${BRANCH} == 'master') {
                	color: 'danger',
                	message: "FAILED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
                }
        }
        fixed {
            slackSend(
                color: 'good',
                message: "FIXED: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})")
        }
    }
}
