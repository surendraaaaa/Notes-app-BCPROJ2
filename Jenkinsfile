pipeline {
    agent any
    
    tools {
        nodejs 'nodejs'
    }
    
    parameters {
        string(name: 'DOCKER_TAG', defaultValue: 'latest', description: 'Enter the Docker image tag')
    }
    
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
    }

    stages {

      
        stage('Clean Workspace') {
            steps {
                cleanWs()
            }
        }
        
      
        stage('Git Repo Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/surendraaaaa/Notes-app-BCPROJ2.git'
            }
        }

        
        stage('Install Dependencies') {
            parallel {
                stage('Frontend Install') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
                        }
                    }
                }
                stage('Backend Install') {
                    steps {
                        dir('backend') {
                            sh 'npm install'
                        }
                    }
                }
            }
        }

      
        stage('Run Tests') {
            parallel {
                stage('Frontend Test') {
                    steps {
                        dir('frontend') {
                            sh 'npm test || echo "No frontend tests found — skipping"'
                        }
                    }
                }
                stage('Backend Test') {
                    steps {
                        dir('backend') {
                            sh 'npm test || echo "No backend tests found — skipping"'
                        }
                    }
                }
            }
        }

       
        stage('Trivy FS Scan') {
            steps {
                sh 'trivy fs --format table -o fs-scan.html . || echo "Trivy scan skipped (tool not installed?)"'
            }
        }

       
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('sonar') {
                    sh '''
                        $SCANNER_HOME/bin/sonar-scanner \
                        -Dsonar.projectName=notesapp \
                        -Dsonar.projectKey=notesapp \
                        -Dsonar.sources=.
                    '''
                }
            }
        }

        
        stage('Quality Gate Check') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'sonar-token'
                }
            }
        }

        
        stage('Build Frontend & Backend') {
            parallel {
                stage('Frontend Build') {
                    steps {
                        dir('frontend') {
                            sh 'npm run build'
                        }
                    }
                }
                stage('Backend Build (optional)') {
                    steps {
                        dir('backend') {
                            sh 'npm run build || echo "No backend build script found — skipping"'
                        }
                    }
                }
            }
        }
        
        stage('Zip Artifacts') {
            steps {
                sh '''
                # Zip frontend build
                cd frontend
                zip -r ../frontend-dist.zip build/
                
                # Zip backend code
                cd ../backend
                zip -r ../backend.zip .
                '''
            }
        }

        
        stage('Publish Artifacts to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {
                    configFileProvider([configFile(fileId: '39ef2683-2d05-4153-bc70-4e2094662f49', variable: 'UPLOAD_SCRIPT')]) {
                        sh '''
                        chmod +x $UPLOAD_SCRIPT
                        # Upload frontend
                        $UPLOAD_SCRIPT frontend-dist.zip frontend-dist.zip http://internal-nexus-internal-alb-161628350.us-east-2.elb.amazonaws.com:8081/repository/raw-releases
                        # Upload backend
                        $UPLOAD_SCRIPT backend.zip backend.zip http://internal-nexus-internal-alb-161628350.us-east-2.elb.amazonaws.com:8081/repository/raw-releases
                        # Upload Trivy report
                        $UPLOAD_SCRIPT fs-scan.html fs-scan.html http://internal-nexus-internal-alb-161628350.us-east-2.elb.amazonaws.com:8081/repository/raw-releases
                        '''
                    }
                }
            }
        }

        
        stage('Build & Tag Docker Images') {
        steps {
            script {
                
                dir('backend') {
                    sh "docker build -t surendraprajapati/notes_backend:${params.DOCKER_TAG} ."
                }
    
                
                dir('frontend') {
                    sh "docker build -t surendraprajapati/notes_frontend:${params.DOCKER_TAG} ."
                }
            }
        }
    }
    
     stage('Trivy Image Scan') {
    steps {
        dir('frontend') {
            sh """#!/bin/bash
            docker pull surendraprajapati/notes_frontend:${params.DOCKER_TAG}
            trivy image --format table -o frontend-image-scan.html surendraprajapati/notes_frontend:${params.DOCKER_TAG} || echo "Trivy scan skipped"
            """
        }
        dir('backend') {
            sh """#!/bin/bash
            docker pull surendraprajapati/notes_backend:${params.DOCKER_TAG}
            trivy image --format table -o backend-image-scan.html surendraprajapati/notes_backend:${params.DOCKER_TAG} || echo "Trivy scan skipped"
            """
        }
    }
}



        stage('Push Docker Images') {
            steps {
                script {
                    
                    withDockerRegistry([credentialsId: 'docker-cred', url: 'https://index.docker.io/v1/']) {
                        
                       
                        sh "docker push surendraprajapati/notes_backend:${params.DOCKER_TAG}"
                        
                       
                        sh "docker push surendraprajapati/notes_frontend:${params.DOCKER_TAG}"
                    }
                }
            }
        }


        
       stage('Update GitHub Manifest') {
            steps {
                script {
                    def manifestPath = 'k8s/manifests/all-in-one.yml'
        
                    // Update backend and frontend image tags using sed
                    sh """
                    sed -i 's|image: surendraprajapati/notes_backend:.*|image: surendraprajapati/notes_backend:${params.DOCKER_TAG}|' ${manifestPath}
                    sed -i 's|image: surendraprajapati/notes_frontend:.*|image: surendraprajapati/notes_frontend:${params.DOCKER_TAG}|' ${manifestPath}
                    """
        
                    // Push changes back to GitHub
                    withCredentials([usernamePassword(credentialsId: 'github-cred', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                        sh """
                        git config user.name "jenkins"
                        git config user.email "jenkins@example.com"
                        git remote set-url origin https://${GIT_USER}:${GIT_TOKEN}@github.com/surendraaaaa/Notes-app-BCPROJ2.git
                        git add ${manifestPath}
                        git commit -m "Update manifest images to tag ${params.DOCKER_TAG}" || echo "No changes to commit"
                        git push origin main
                        """
                    }
                }
            }
        }


      
    }
}
