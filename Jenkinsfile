pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 10, unit: 'MINUTES')
    }

    stages {

        stage('Clean-Up') {
            steps {
                sh 'docker rm -f flask-app || true'
                sh 'docker rm -f nginx || true'
            }
        }

        stage('Set-Up') {
            steps {
                sh 'docker network create silver-network || true'
            }
        }

        stage('Build Images') {
            steps {
                sh 'docker build -t flask-app .'
                sh 'docker build -t nginx-proxy ./nginx'
            }
        }

        stage('Run Containers') {
            steps {

                sh '''
                docker run -d \
                --name flask-app \
                --network silver-network \
                flask-app
                '''

                sh '''
                docker run -d \
                --name nginx \
                --network silver-network \
                -p 80:80 \
                nginx-proxy
                '''
            }
        }

    }

    post {
        always {
            sh 'docker ps -a'
        }
    }
}
