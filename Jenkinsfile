pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/Syeeda-Zooni/uptimeguard.git'
            }
        }

        stage('Build Stable Image (v1)') {
            steps {
                sh "docker build --build-arg APP_VERSION=v1 --build-arg FEATURE_INCIDENTS=false -t ${ECR_REPO}:v1 appfiles/"
            }
        }

        stage('Build Canary Image (v2)') {
            steps {
                sh "docker build --build-arg APP_VERSION=v2 --build-arg FEATURE_INCIDENTS=true -t ${ECR_REPO}:v2 appfiles/"
            }
        }

        stage('Login to ECR') {
            steps {
                sh "aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${ECR_REPO}"
            }
        }

        stage('Push Images') {
            steps {
                sh "docker push ${ECR_REPO}:v1"
                sh "docker push ${ECR_REPO}:v2"
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'pulseguard-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                        envsubst < k8s/namespace.yml | kubectl apply -f -
                        envsubst < k8s/stable-deployment.yaml | kubectl apply -f -
                        envsubst < k8s/canary-deployment.yml | kubectl apply -f -
                        envsubst < k8s/service.yml | kubectl apply -f -
                    '''
                }
            }
        }

        stage('Monitor Canary Health') {
            steps {
                withCredentials([file(credentialsId: 'pulseguard-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                        echo "Canary pod status:"
                        kubectl get pods -n uptimeguard -l track=canary
                        echo ""
                        echo "Check the app and Grafana dashboard, then decide."
                    '''
                }
                input message: "Is the canary version healthy? Promote to stable, or abort to roll back.", ok: "Promote"
            }
        }

        stage('Promote Canary to Stable') {
            steps {
                withCredentials([file(credentialsId: 'pulseguard-kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                        kubectl set image deployment/uptimeguard-stable-dep uptimeguard-stable-container=${ECR_REPO}:v2 -n uptimeguard
                        kubectl rollout status deployment/uptimeguard-stable-dep -n uptimeguard
                        kubectl scale deployment/uptimeguard-canary-dep --replicas=0 -n uptimeguard
                    '''
                }
            }
        }
    }

    post {
        aborted {
            withCredentials([file(credentialsId: 'pulseguard-kubeconfig', variable: 'KUBECONFIG')]) {
                sh '''
                    echo "Canary rejected — rolling back."
                    kubectl scale deployment/uptimeguard-canary-dep --replicas=0 -n uptimeguard
                '''
            }
        }
    }
}
