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
        stage('rust') {
            when { branch 'master' }
            steps {
                sh 'curl https://sh.rustup.rs -sSf | sh -s -- -y'
                sh 'source $HOME/.cargo/env'
                sh '/Users/synctesting/.cargo/bin/rustup target add aarch64-apple-ios armv7-apple-ios armv7s-apple-ios x86_64-apple-ios i386-apple-ios'
                sh '''
                    if ! [ -x "$(command -v /Users/synctesting/.cargo/bin/cargo-lipo)" ] ; then
                    echo "Cargo-lipo is not installed, installing"
                    /Users/synctesting/.cargo/bin/cargo install cargo-lipo
                    else
                    echo "cargo-lipo installed"
                    fi
                    '''
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
                    sh 'pipenv check'
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
