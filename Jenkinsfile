pipeline {
    agent any

    options {
        timestamps()
        timeout(time: 15, unit: 'MINUTES')
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
                sh 'mkdir -p trivy-results'
            }
        }

        stage('Unit Tests') {
            steps {
                sh '''
		rm -rf venv

		python3 -m venv venv
		. venv/bin/activate
		
		python -m pip install --upgrade pip
		
		pip install -r requirements.txt
		
		pytest
		'''
            }
        }

        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs . > trivy-results/fs-scan.txt'
            }
        }

        stage('Build Images') {
            steps {
                sh 'docker build -t flask-app .'
                sh 'docker build -t nginx-proxy ./nginx'
            }
        }

        stage('Trivy Image Scan') {
            steps {
                sh 'trivy image flask-app > trivy-results/image-scan.txt'
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
            archiveArtifacts artifacts: 'trivy-results/*.txt', allowEmptyArchive: true
        }
    }
}
