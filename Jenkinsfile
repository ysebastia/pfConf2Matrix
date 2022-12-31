pipeline {
    agent any
    environment {
        release_pfconf2matrix = "ysebastia/pfconf2matrix:1.0"
        QUALITY_DOCKERFILE = "1"
    }
    stages {
        stage ('Checkout') {
            agent any
            steps {
                checkout([
                  $class: 'GitSCM',
                  branches: [[name: '*/main']],
                  extensions: [[$class: 'CleanBeforeCheckout', deleteUntrackedNestedRepositories: true]],
                  userRemoteConfigs: [[url: 'https://github.com/ysebastia/pfConf2Matrix.git']]
              ])
            }
        }
        stage('QA') {
        parallel {
                stage ('cloc') {
              agent {
                  docker {
                      image 'ysebastia/cloc:1.96'
                  }
                }
                  steps {
                      sh 'cloc --by-file --xml --fullpath --out=build/cloc.xml ./'
                      sloccountPublish encoding: '', pattern: 'build/cloc.xml'
                      archiveArtifacts artifacts: 'build/cloc.xml', followSymlinks: false
                      sh 'rm build/cloc.xml'
                  }
                }
            stage ('hadolint') {
                agent {
                    docker {
                          image 'docker.io/hadolint/hadolint:v2.12.0-alpine'
                      }
              }
                steps {
                    sh 'touch hadolint.json'
                    sh 'hadolint -f json src/*/Dockerfile | tee -a hadolint.json'
                  recordIssues qualityGates: [[threshold: QUALITY_DOCKERFILE, type: 'TOTAL', unstable: false]], tools: [hadoLint(pattern: 'hadolint.json')]
                    archiveArtifacts artifacts: 'hadolint.json', followSymlinks: false
                    sh 'rm hadolint.json'
                }
            }
        }
        }
        stage('Build') {
            parallel {
                stage('pfConf2Matrix') {
                    agent any
                    steps {
                        script {
                            withDockerRegistry(credentialsId: 'docker') {
                                docker.build("${env.release_pfconf2matrix}", "src").push()
                            }
                        }
                    }
                }
            }
        }
    }
    post {
       always {
         cleanWs()
       }
    }
}
