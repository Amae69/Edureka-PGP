pipeline {
    agent any

    environment {
        DOCKER_CREDS = credentials('dockerhub')
        AWS_CREDS = credentials('aws-creds')
        APP_URL = "http://localhost:8080" // Will be overridden dynamically
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

        stage('Compile, Test & Package') {
            steps {
                sh 'mvn clean compile test package'
            }
        }

        stage('Dependency Check (SCA)') {
            steps {
                sh '''
                mkdir -p reports-${BUILD_NUMBER}
                chmod 777 reports-${BUILD_NUMBER}
                docker run --rm \
                -v odc-workspace-data:/usr/share/dependency-check/data \
                -v $(pwd):/src \
                -v $(pwd)/reports-${BUILD_NUMBER}:/report \
                owasp/dependency-check \
                --scan /src \
                --format HTML \
                --out /report
                '''
                archiveArtifacts artifacts: "reports-${BUILD_NUMBER}/*.html", allowEmptyArchive: true
            }
        }

        stage('Checkov Scan') {
            steps {
                sh '''
                docker run --rm -v $(pwd)/terraform:/tf bridgecrew/checkov -d /tf || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    cp target/ABCtechnologies*.war abc_tech.war || cp target/*.war abc_tech.war
                    docker build -t krizeal/abc_tech:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Push Docker Image') {
            steps {
                sh '''
                    echo $DOCKER_CREDS_PSW | docker login -u $DOCKER_CREDS_USR --password-stdin
                    docker push krizeal/abc_tech:${BUILD_NUMBER}
                '''
            }
        }

        stage('Terraform Init & Apply') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-creds',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                    cd terraform
                    terraform init
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Get Public IPs') {
            steps {
                script {
                    def ip = sh(
                        script: "cd terraform && terraform output -raw app_public_ip",
                        returnStdout: true
                    ).trim()
                    def mon_ip = sh(
                        script: "cd terraform && terraform output -raw monitoring_public_ip",
                        returnStdout: true
                    ).trim()

                    env.APP_IP = ip
                    env.MON_IP = mon_ip
                    env.APP_URL = "http://${ip}:8080"
                    
                    echo "App IP is ${env.APP_IP}"
                    echo "Monitoring IP is ${env.MON_IP}"
                    echo "App URL is ${env.APP_URL}"
                }
            }
        }

        stage('Ansible Configuration') {
            steps {
                script {
                    // Generate dynamic inventory file
                    sh """
                    echo '[app]' > ansible/inventory.ini
                    echo '${env.APP_IP} ansible_user=ubuntu ansible_ssh_common_args="-o StrictHostKeyChecking=no"' >> ansible/inventory.ini
                    echo '[monitoring]' >> ansible/inventory.ini
                    echo '${env.MON_IP} ansible_user=ubuntu ansible_ssh_common_args="-o StrictHostKeyChecking=no"' >> ansible/inventory.ini
                    """

                    // Run Ansible Playbook for App Setup
                    withCredentials([sshUserPrivateKey(credentialsId: 'aws-ssh-key', keyFileVariable: 'SSH_KEY')]) {
                        sh "ansible-playbook -i ansible/inventory.ini --private-key \$SSH_KEY ansible/setup-app.yml --extra-vars 'build_number=${BUILD_NUMBER}'"
                        sh "ansible-playbook -i ansible/inventory.ini --private-key \$SSH_KEY ansible/setup-monitoring.yml --extra-vars 'app_server_ip=${env.APP_IP}'"
                    }
                }
            }
        }

        stage('OWASP ZAP (DAST)') {
            steps {
                sh """
                mkdir -p zap-report
                chmod 777 zap-report
                docker run --rm -v \$(pwd)/zap-report:/zap/wrk/:rw -t zaproxy/zap-stable \
                zap-baseline.py \
                -t http://${env.APP_IP}:8080/abc_tech/ \
                -r zap-report.html || true
                """
                archiveArtifacts artifacts: 'zap-report/zap-report.html', allowEmptyArchive: true
            }
        }
    }
}
