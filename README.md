# End-to-End Deployment of Containerized Applications Using DevOps, GitOps, and DevSecOps with CI/CD Pipelines

## Diagram
<img width="975" height="380" alt="image" src="https://github.com/user-attachments/assets/56686b83-d57e-455d-b2fa-36d6d15bdf88" />


## Project Overview

This project demonstrates a complete end-to-end DevOps pipeline for a full-stack CRUD Notes Application. The application consists of:

- **Frontend**: React.js
- **Backend**: Node.js/Express
- **Database**: MySQL

The pipeline incorporates secure build practices, static code analysis, vulnerability scanning, artifact management, containerization, GitOps-based deployment, and Kubernetes orchestration.



## Problem Statement

The company requires a fully automated DevOps CI/CD pipeline capable of handling both containerized and non-containerized applications. The pipeline must incorporate:

- Secure build practices
- Static code analysis
- Vulnerability scanning
- Artifact management
- Containerization
- GitOps-based deployment
- Kubernetes orchestration

## CI/CD Pipeline Architecture

The CI/CD pipeline is implemented using Jenkins and follows an enterprise-grade workflow:

### Pipeline Stages:
1. **Workspace cleanup**
2. **Git checkout** from GitHub
3. **Installing dependencies** for frontend and backend
4. **Running Jest tests** (if available)
5. **Filesystem vulnerability scanning** using Trivy
6. **Code quality analysis** via SonarQube
7. **Quality gate enforcement**
8. **Frontend and backend build steps**
9. **Packaging artifacts** into zip files
10. **Uploading artifacts** to Nexus Repository
11. **Docker image build and tag**
12. **Trivy image scanning**
13. **Pushing images** to Docker Hub
14. **Auto updating Kubernetes manifests** with new image tags

## Tech Stack

### DevOps & CI/CD
- **CI/CD Pipeline**: Jenkins, ArgoCD
- **Code Quality & Security**: SonarQube, Trivy
- **Artifact Management**: Nexus Repository
- **Containerization**: Docker
- **Container Registry**: Docker Hub
- **GitOps CD**: ArgoCD

### Kubernetes & Infrastructure
- **Kubernetes**: Amazon EKS (Elastic Kubernetes Service)
- **K8s Components**: Deployments, Services, ConfigMaps, Secrets, PersistentVolumeClaims, StorageClass (AWS EBS CSI), Ingress (ALB via LoadBalancer)
- **Storage & Volume Management**: AWS EBS CSI Driver
- **Ingress**: AWS Load Balancer Controller
- **Monitoring & Observability**: Prometheus and Grafana

### Infrastructure as Code (IaC)
- **Terraform** for:
  - VPC, Subnets, Route Tables
  - Internet Gateway, NAT Gateway
  - Security Groups
  - EC2 for Jenkins, SonarQube, Nexus
  - EKS cluster + node groups
  - ALB

### Tools Used
- Kubectl, eksctl, Helm, zip/unzip, curl, AWS CLI

## Infrastructure Creation

```bash
cd infra/
terraform init
terraform validate
terraform plan
terraform apply -auto-approve
```

## 🔐 Server Access and Configurations

### 🖥️ Jenkins Server Setup
```bash
# SSH into public subnet Jenkins server
ssh -i yourkey.pem ubuntu@<Jenkins-Public-IP>

# Install required packages
sudo apt-get update
sudo apt-get install -y libatomic1 build-essential
sudo apt-get install -y zip
```

## 🌐 Bastion Host Configuration
### SSH into bastion host to connect to SonarQube and Nexus servers.

## 📊 SonarQube Installation
```bash
# Step 1: SSH into SonarQube via bastion host
ssh -i yourkey.pem ubuntu@<sonar-private-ip>

# Step 2: Install Docker
sudo apt install docker.io
sudo usermod -aG docker $USER
newgrp docker

# Step 3: Install SonarQube
docker run -d --name sonar -p 9000:9000 mc1arke/sonarqube-with-community-branch-plugin

# Step 4: Create tunnel to access SonarQube server on localhost
# From your local laptop in PowerShell:
ssh -i yourkey.pem -L 9000:10.0.11.10:9000 ubuntu@18.223.170.130
```
Access SonarQube locally: 👉 http://localhost:9000

## 📦 Nexus Server Installation
```bash
# From bastion host
ssh -i yourkey.pem ubuntu@10.0.12.10

# Run Nexus container
docker run -d --name nexus -p 8081:8081 sonatype/nexus3

# Create tunnel from local PowerShell
ssh -i yourkey.pem -L 8081:10.0.12.10:8081 ubuntu@18.223.170.130

# Get Nexus admin password
docker exec -it <container_id> /bin/sh
cd sonatype-work/nexus3
cat admin.password
# use this password to login into nexus server
```
Access Nexus locally: 👉 http://localhost:8081

## ⚙️ Jenkins Configuration

### 🔑 Initial Setup
- Access Jenkins UI on **port 8080**
- Get initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### 📦 Install Required Plugins
Install the following plugins through Jenkins UI:

Docker
SonarQube Scanner
NodeJS
GitHub
Pipeline
Kubernetes

### 🐳 Docker Installation on Jenkins
``` bash
sudo apt update
sudo apt install ca-certificates curl

# Create keyrings directory
sudo install -m 0755 -d /etc/apt/keyrings

# Add Docker’s official GPG key
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$UBUNTU_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

# Install Docker
sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins
```

### 🔐 Trivy Installation
``` bash
# Clone tools installation repository
git clone https://github.com/surendraaaaa/Tools-installation.git

# Follow installation instructions from the repository

# Verify installation
trivy --version
```
### 🛠️ Tool Configuration in Jenkins
## ⚙️ Jenkins Tool Configuration

### 🟦 Node.js Configuration
1. Navigate to **Manage Jenkins → Tools**  
2. Under **NodeJs**, add a new Node.js installation  
   - Provide a name (e.g., `NodeJS-16`)  
   - Select the desired Node.js version  

---

### 📊 SonarQube Configuration
1. Go to the **SonarQube server**  
2. Create a **token** under:  
   `Security → Users → Tokens`  
3. Add the token to **Jenkins credentials**  
4. In Jenkins, navigate to:  
   **Manage Jenkins → System → SonarQube installation**  
   - Add the **internal ALB URL** with port `9000`  
   - Provide the **SonarQube token**  
5. Configure a **webhook** in SonarQube server:  
   - Navigate to **Administration → Configuration → Webhooks**  
   - Add Jenkins webhook URL (internal ALB endpoint)  
   - Save configuration  

---

✅ With this setup, Jenkins can run **SonarQube scans**, enforce **quality gates**, and integrate Node.js builds seamlessly into the CI/CD pipeline.

## 📦 Nexus Configuration

### 🔧 Create Raw Repository
- In Nexus, create a **Raw repository** for storing artifacts.  
- Example URL:  
http://internal-nexus-internal-alb-161628350.us-east-2.elb.amazonaws.com:8081/repository/raw-releases/


---

### 📜 Custom Upload Script (Jenkins Managed Files)
Add the following script in **Jenkins Managed Files** to automate artifact uploads:

```bash
#!/bin/bash
# Nexus upload script for Jenkins Managed Files
# Usage: ./upload-to-nexus.sh <artifact-path> <artifact-name> <nexus-url>

ARTIFACT_PATH=$1
ARTIFACT_NAME=$2
NEXUS_URL=$3

if [[ -z "$ARTIFACT_PATH" || -z "$ARTIFACT_NAME" || -z "$NEXUS_URL" ]]; then
  echo "Usage: $0 <artifact-path> <artifact-name> <nexus-url>"
  exit 1
fi

echo "Uploading $ARTIFACT_NAME to Nexus repository..."

curl -u $NEXUS_USER:$NEXUS_PASS --fail --show-error --upload-file "$ARTIFACT_PATH" \
"$NEXUS_URL/$ARTIFACT_NAME"

if [[ $? -eq 0 ]]; then
  echo "✅ Successfully uploaded $ARTIFACT_NAME"
else
  echo "❌ Failed to upload $ARTIFACT_NAME"
  exit 1
fi
```
## 🔐 Nexus Credentials

1. Navigate to **Manage Jenkins → Credentials**  
2. Create a new credential using your **Nexus username and password**  
   - ID: `nexus-credentials` (example)  
   - Username: `<your-nexus-username>`  
   - Password: `<your-nexus-password>`  
3. Reference these credentials in the **Nexus upload script** for authentication:

```bash
curl -u $NEXUS_USER:$NEXUS_PASS --fail --show-error --upload-file "$ARTIFACT_PATH" \
"$NEXUS_URL/$ARTIFACT_NAME"
```

## 🐳 Docker Configuration
1. Navigate to **Manage Jenkins → Credentials**  
2. Create a new credential for **Docker Hub**:  
   - ID: `docker-hub-credentials` (example)  
   - Username: `<your-dockerhub-username>`  
   - Password / Token: `<your-dockerhub-password-or-token>`  
3. Use these credentials in the Jenkins pipeline to authenticate and push Docker images to Docker Hub.

---

## 🐙 GitHub Configuration
1. Navigate to **Manage Jenkins → Credentials**  
2. Create a new credential for **GitHub**:  
   - ID: `github-credentials` (example)  
   - Username: `<your-github-username>`  
   - Personal Access Token: `<your-github-token>`  
3. These credentials are used by Jenkins to:  
   - Push changes to Kubernetes manifest files in the GitHub repository  
   - Trigger GitOps deployments via ArgoCD webhook  

---

✅ With these configurations, Jenkins can securely interact with **Docker Hub** for image publishing and **GitHub** for manifest updates, enabling a seamless CI/CD + GitOps workflow.

## 🚀 CD Pipeline Setup

### 🛠️ Kubernetes Tools Installation

#### 📦 kubectl Installation
```bash
# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version
```
### 📦 eksctl Installation
``` bash
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Verify installation
eksctl version
```
## ⚙️ Cluster Configuration
### 🔄 Update Kubeconfig
``` bash
aws eks --region us-east-2 update-kubeconfig --name my-cluster
```
### ✅ Verify Cluster Access
``` bash
kubectl get nodes
```

### 🔐 Install OIDC Provider
``` bash
eksctl utils associate-iam-oidc-provider \
  --region us-east-2 \
  --cluster my-cluster \
  --approve
```

### 📦 Create Service Account for EBS
``` bash
eksctl create iamserviceaccount \
  --region us-east-2 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster my-cluster \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts
```

### ✅ With these steps, the Kubernetes cluster is fully configured with kubectl, eksctl, OIDC provider, and an EBS CSI service account for persistent storage management.

## 📦 Helm Installation and Package Management

### ⚙️ Install EBS CSI Controller and Cert-Manager

```bash
# Add the EBS CSI Helm repo
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update

# Install the driver using the service account we created
helm install aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver \
  --namespace kube-system \
  --set serviceAccount.create=false \
  --set serviceAccount.name=ebs-csi-controller-sa

# Add Jetstack Helm repo for cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --set installCRDs=true
```
## 🚀 ArgoCD Setup
### 📥 Installation
``` bash
# Step 1: Create argocd namespace
kubectl create ns argocd

# Step 2: Install ArgoCD in the cluster
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Step 3: Check if all resources are created
kubectl get all -n argocd
```
### ⚙️ Service Configuration
``` bash
# Edit argocd service to LoadBalancer
kubectl edit svc argocd-server -n argocd
```
### 🔐 Access and Authentication
``` bash
# Get the ArgoCD URL
kubectl get svc -n argocd

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode && echo
```

## 📂 Repository Configuration

### 🔑 Login to ArgoCD UI
1. Open the **ArgoCD UI** in your browser  
2. Navigate to **Settings → Repositories**  
3. Add your **GitHub repository** containing the Kubernetes manifests  

---

## 📦 Storage Class Configuration

Create a storage class for **AWS EBS gp3**:

```yaml
# storageclass.yml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-ebs
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  type: gp3
  encrypted: "true"
```
### Apply the storage class:
``` bash
kubectl apply -f storageclass.yml
```
## 🚀 Application Creation

1. Open the **ArgoCD UI** in your browser  
2. Navigate to **Applications → New Application**  
3. Provide the following details:  
   - **Repository URL:** Your GitHub repository containing Kubernetes manifests  
   - **Path:** Directory where manifests are stored (e.g., `k8s/manifests/`)  
   - **Cluster & Namespace:** Target Kubernetes cluster and namespace  
4. Click **Create** to register the application  
5. Hit **Sync** to deploy resources from GitHub to your Kubernetes cluster  

---
### 🔐 GitHub Webhook Configuration
### Set the webhook secret in ArgoCD:
``` bash
SECRET="githubwebhooksecret1234"
kubectl -n argocd patch secret argocd-secret -p '{"stringData": {"github.webhook.secret": "'"$SECRET"'"}}'
```
## 🐙 GitHub Repository Webhook Setup

1. Go to your **GitHub repository → Settings → Webhooks**  
2. Click **Add webhook**  
3. Fill in the following details:

- **Payload URL:**
https://<your-argocd-url>/api/webhook
- **Content type:**  
`application/json`  
- **Secret:**  
`githubwebhooksecret1234`  

4. Save the webhook configuration  

---

✅ With this setup, every commit to your GitHub repository will automatically trigger **ArgoCD** to sync and deploy the latest Kubernetes manifests.

## 📊 Monitoring with Prometheus and Grafana

### ⚙️ Installation

```bash
# Add the Prometheus Community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Add the Grafana Helm repo
helm repo add grafana https://grafana.github.io/helm-charts

# Update repos
helm repo update

# Create Namespace
kubectl create namespace monitoring

# Install Prometheus and Grafana on EKS
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --set grafana.service.type=LoadBalancer \
  --set prometheus.service.type=LoadBalancer
  ```
### 🔐 Access Grafana
```bash
# Get Grafana admin password
kubectl --namespace monitoring get secret prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d ; echo
```
## 📊 Import Dashboards

### 🔎 Access Grafana UI
1. Open the **Grafana UI** via the LoadBalancer URL  
2. Import dashboards using the following codes:  
   - **315** → Kubernetes Cluster Monitoring  
   - **15661** → DevOps & Node Monitoring (for better visibility)  

---

## ✅ Results

### 🚀 CI Pipeline Success
- Jenkins Pipeline ran successfully with parameters  
- Docker image tags updated automatically  
- Manifest files updated on GitHub repo  

---

### 📦 Artifact Management
- All artifacts and scan results saved in **Nexus repository**  

---

### 📊 Code Quality
- SonarQube scan results available  
- Quality gate checks passed  

---

### 🐳 Container Registry
- Docker images successfully pushed to **Docker Hub registry**  

---

### 🔄 GitOps Deployment
- GitHub repository updated by Jenkins pipeline  
- Image tags automatically updated in Kubernetes manifest files  
- Application successfully deployed on **EKS cluster**  

---

### 🌐 Application Access
The **3-tier CRUD Notes Application** is accessible via the **Load Balancer URL**, allowing users to:
- Create notes  
- Read notes  
- Update notes  
- Delete notes  

---

## 🏗️ Application Architecture
The deployed application showcases:
- **Frontend:** React.js application serving the user interface  
- **Backend:** Node.js/Express API handling business logic  
- **Database:** MySQL for persistent data storage  
- **Kubernetes:** Orchestration and scaling  
- **Monitoring:** Real-time observability with Prometheus and Grafana  

---

## 🔐 Security Features
- **Vulnerability Scanning:** Trivy scans for container vulnerabilities  
- **Static Code Analysis:** SonarQube ensures code quality  
- **Secrets Management:** Kubernetes secrets for sensitive data  
- **Network Security:** Properly configured security groups and network policies  

---

✅ This project demonstrates a **production-ready DevOps pipeline** that incorporates industry best practices for **security, automation, and reliability**.







