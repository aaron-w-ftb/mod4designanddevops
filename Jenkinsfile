pipeline {

    agent any

    environment {

        APP_IMAGE = "flask-app"

        NGINX_IMAGE = "nginx-proxy"

        NETWORK = "silver-network"

        DOCKER_USER = "aaronwftb"

        IMAGE_TAG = "${BUILD_NUMBER}"

        DOCKERHUB_CREDS = credentials('dockerhub-creds')
    }

    options {

        timestamps()

        timeout(time: 30, unit: 'MINUTES')
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

                sh 'docker network create ${NETWORK} || true'

                sh 'mkdir -p trivy-results'

                sh 'mkdir -p metadata'

                sh 'mkdir -p sbom'
            }
        }

        stage('Initial Checks') {

            parallel {

                stage('Trivy FS Scan') {

                    steps {

                        sh '''
                        trivy fs . \
                        --format table \
                        > trivy-results/fs-scan.txt
                        '''
                    }
                }

                stage('Python Environment Test') {

                    steps {

                        sh '''
                        rm -rf venv

                        python3 -m venv venv

                        . venv/bin/activate

                        python -m pip install --upgrade pip

                        pip install -r requirements.txt
                        '''
                    }
                }
            }
        }

        stage('Build Images') {

            parallel {

                stage('Build Flask Image') {

                    steps {

                        sh '''
                        docker build \
                        -t ${APP_IMAGE}:latest .
                        '''
                    }
                }

                stage('Build Nginx Image') {

                    steps {

                        sh '''
                        docker build \
                        -t ${NGINX_IMAGE}:latest ./nginx
                        '''
                    }
                }
            }
        }

        stage('Image Size Check') {

            steps {

                script {

                    def size = sh(
                        script: "docker image inspect ${APP_IMAGE}:latest --format='{{.Size}}'",
                        returnStdout: true
                    ).trim()

                    def sizeMB = size.toInteger() / (1024 * 1024)

                    echo "Image size: ${sizeMB} MB"

                    if (sizeMB > 200) {

                        error("Image exceeds 200MB")
                    }
                }
            }
        }

        stage('Trivy Image Scan') {

            steps {

                sh '''
                trivy image \
		--scanners vuln \
                --severity HIGH,CRITICAL \
		--ignore-unfixed \
                --exit-code 1 \
                ${APP_IMAGE}:latest \
                > trivy-results/image-scan.txt
                '''
            }
        }

        stage('Generate SBOM') {

            steps {

                sh '''
                trivy image \
                --format cyclonedx \
                --output sbom/flask-sbom.json \
                ${APP_IMAGE}:latest
                '''
            }
        }

        stage('Generate Metadata') {

            steps {

                sh '''
                echo "Build Number: ${BUILD_NUMBER}" \
                > metadata/build-info.txt

                echo "Build Date: $(date)" \
                >> metadata/build-info.txt

                echo "Git Commit:" \
                >> metadata/build-info.txt

                git rev-parse HEAD \
                >> metadata/build-info.txt
                '''
            }
        }

        stage('Approval Gate') {

            steps {

                input message: 'Approve deployment?', ok: 'Deploy'
            }
        }

        stage('DockerHub Login') {

            steps {

                sh '''
                echo $DOCKERHUB_CREDS_PSW | docker login \
                -u $DOCKERHUB_CREDS_USR \
                --password-stdin
                '''
            }
        }

        stage('Push Images') {

            steps {

                sh '''
                docker tag ${APP_IMAGE}:latest \
                ${DOCKER_USER}/${APP_IMAGE}:${IMAGE_TAG}
                '''

                sh '''
                docker push \
                ${DOCKER_USER}/${APP_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Run Containers') {

            steps {

                sh '''
                docker run -d \
                --name flask-app \
                --network ${NETWORK} \
                ${APP_IMAGE}:latest
                '''

                sh '''
                docker run -d \
                --name nginx \
                --network ${NETWORK} \
                -p 80:80 \
                ${NGINX_IMAGE}:latest
                '''
            }
        }

        stage('Unit Tests') {

            steps {

                catchError(buildResult: 'UNSTABLE', stageResult: 'UNSTABLE') {

                    sh '''
                    . venv/bin/activate

                    python3 test_app.py
                    '''
                }
            }
        }

        stage('Smoke Tests') {

            steps {

                sh '''
                curl -f http://localhost
                '''
            }
        }
    }

    post {

        always {

            archiveArtifacts artifacts: '''
            trivy-results/*.txt,
            metadata/*,
            sbom/*
            ''', allowEmptyArchive: true
        }
    }
}

