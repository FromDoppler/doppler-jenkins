pipeline {
    agent any
    stages {
        stage('Verify git commit conventions') {
            when {
                not {
                    branch 'INT'
                }
            }
            steps {
                sh 'sh ./gitlint.sh'
            }
        }
        stage('Verify Dockerfile lint') {
            steps {
                sh 'sh ./dockerlint.sh'
            }
        }
        stage('Verify .sh files') {
            steps {
                sh 'docker build --target verify-sh .'
            }
        }
        stage('Verify Format') {
            steps {
                sh 'docker build --target verify-format .'
            }
        }
        stage('Build') {
            steps {
                sh 'docker build .'
            }
        }
        stage('Publish in dopplerdock') {
            environment {
                DOCKER_CREDENTIALS_ID = "dockerhub_dopplerdock"
                DOCKER_IMAGE_NAME = "dopplerdock/doppler-jenkins"
            }
            stages {
                stage('Publish pre-release images from pull request') {
                    when {
                        changeRequest target: 'main'
                    }
                    steps {
                        withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS_ID}", url: "") {
                            sh '''
                              sh build-n-publish.sh \
                                --image=${DOCKER_IMAGE_NAME} \
                                --commit=${GIT_COMMIT} \
                                --name=pr-${CHANGE_ID}
                            '''
                        }
                    }
                }
                stage('Publish pre-release images from main') {
                    when {
                        branch 'main'
                    }
                    steps {
                        withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS_ID}", url: "") {
                            sh '''
                              sh build-n-publish.sh \
                                --image=${DOCKER_IMAGE_NAME} \
                                --commit=${GIT_COMMIT} \
                                --name=main
                              '''
                        }
                    }
                }
                stage('Publish pre-release images from INT') {
                    when {
                        branch 'INT'
                    }
                    steps {
                        withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS_ID}", url: "") {
                            sh '''
                              sh build-n-publish.sh \
                                --image=${DOCKER_IMAGE_NAME} \
                                --commit=${GIT_COMMIT} \
                                --name=INT
                              '''
                        }
                    }
                }
                stage('Publish final version images') {
                    when { tag pattern: "v\\d+\\.\\d+\\.\\d+", comparator: "REGEXP" }
                    steps {
                        withDockerRegistry(credentialsId: "${DOCKER_CREDENTIALS_ID}", url: "") {
                            sh '''
                              sh build-n-publish.sh \
                                --image=${DOCKER_IMAGE_NAME} \
                                --commit=${GIT_COMMIT} \
                                --version=${TAG_NAME}
                            '''
                        }
                    }
                }
            }
        }
    }
}
