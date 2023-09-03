def hadolint(quality) {
  sh 'touch hadolint.json'
  sh '/usr/local/bin/hadolint.bash | tee -a hadolint.json'
  recordIssues enabledForFailure: true, qualityGates: [[threshold: quality, type: 'TOTAL', unstable: false]], tools: [hadoLint(pattern: 'hadolint.json')]
  archiveArtifacts artifacts: 'hadolint.json', followSymlinks: false
  sh 'rm hadolint.json'
}
pipeline {
    agent any
    environment {
        release_pfconf2matrix = "ysebastia/pfconf2matrix:1.1"
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
                      label 'docker'
                      image 'ysebastia/cloc:1.98'
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
                          label 'docker'
                          image 'docker.io/ysebastia/hadolint:2.12.0-1'
                      }
              }
                steps {
                    hadolint(QUALITY_DOCKERFILE)
                }
            }
        }
        }
        stage('Build') {
            parallel {
                stage('pfConf2Matrix') {
                    agent {
                      label 'docker'
                    }
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
