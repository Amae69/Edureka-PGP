# DevOps Capstone Project: Secure, Automated, and Monitored AWS Infrastructure

This repository contains the complete solution for building a modern DevOps pipeline and provisioning a secure, monitored infrastructure on AWS. 

The project uses **Terraform** for Infrastructure as Code (IaC), **Ansible** for configuration management, **Docker** for containerization, and **Jenkins** for a fully automated CI/CD and DevSecOps pipeline. **Prometheus** and **Grafana** are used to collect and visualize real-time resource metrics.

## Features
- **Infrastructure as Code**: Terraform provisions 3 EC2 instances (Jenkins Server, App Server, and Monitoring Server) securely in AWS.
- **Configuration Management**: Ansible automates the installation of Jenkins, Docker, Node Exporter, Prometheus, and Grafana across the environments.
- **DevSecOps Pipeline**: Jenkins fully automates code checkout, Maven build, Docker packaging, and pushing. It integrates **Continuous Security** with:
  - OWASP Dependency-Check (SCA)
  - Checkov for Terraform vulnerability scanning
  - OWASP ZAP for Dynamic Application Security Testing (DAST)
- **Monitoring & Observability**: Node Exporter streams metrics to Prometheus, which are visualized elegantly using Grafana dashboards.

## Repository Structure
- `src/` & `pom.xml`: Java web application source code.
- `Dockerfile`: Multi-stage build manifest for packaging the Java app using Tomcat.
- `terraform/`: Contains `main.tf`, `variables.tf`, and `outputs.tf` for deploying the AWS infrastructure.
- `ansible/`: Contains playbooks (`setup-jenkins.yml`, `setup-app.yml`, `setup-monitoring.yml`) and `inventory.ini` to configure the servers.
- `Jenkinsfile`: The declarative pipeline script for Jenkins automation.
- `Guide.md`: Detailed, step-by-step setup instructions.

## Prerequisites
- An AWS Account with an IAM Access Key and Secret Key.
- SSH Key Pair created in my AWS region (default `ec2-key`) saved to my local machine.
- Terraform and Ansible installed on my local control machine.
- A free DockerHub account.

## Quick Start Guide

For full details, reference the comprehensive [Guide.md](./Guide.md) file included in this repository.

### 1. Provision Infrastructure
Deploy the three servers to AWS:
```bash
cd terraform
terraform init
terraform apply -auto-approve
```
Take note of the 3 Public IPs output by Terraform.

### 2. Configure Servers
Update the `ansible/inventory.ini` placeholder IPs with your Terraform outputs, then execute:
```bash
ansible-playbook -i ansible/inventory.ini ansible/setup-jenkins.yml
ansible-playbook -i ansible/inventory.ini ansible/setup-app.yml
ansible-playbook -i ansible/inventory.ini ansible/setup-monitoring.yml
```

### 3. Setup Jenkins & Run Pipeline
1. SSH into the Jenkins Server and grab the initial admin password from `/var/lib/jenkins/secrets/initialAdminPassword`.
2. Login at `http://<JENKINS_IP>:8080`, install the **Docker Pipeline** and **AWS Credentials** plugins.
3. Configure your AWS (`aws-creds`) and DockerHub (`dockerhub`) credentials in Jenkins globally.
4. Create a new Pipeline job pointing to this repository and let the `Jenkinsfile` deploy your application automatically!

### 4. Monitor Health
1. Access Grafana at `http://<MONITORING_IP>:3000` (default login: `admin`/`admin`).
2. Add a `Prometheus` data source pointing to `http://localhost:9090`.
3. Import the Node Exporter Full dashboard (ID: `1860`) to view live CPU, Memory, Network, and Disk telemetry!
