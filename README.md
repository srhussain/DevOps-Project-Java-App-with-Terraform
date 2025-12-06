# DevOps-Project-Java-App-with-Terraform

# Java Login App Deployment with Terraform and ALB

This repository contains a **Java Login Application** deployment setup using **Terraform**, **ALB (Application Load Balancer)**, and **Docker Compose**. The deployment is automated via a `deploy.sh` script.

---

## Prerequisites

Before running the deployment, make sure you have the following installed on your machine:

1. **AWS CLI v2**  
   - Install AWS CLI: [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)  
   - Configure AWS CLI with your credentials:
     ```bash
     aws configure
     ```
     Provide your `AWS Access Key`, `Secret Key`, default region (e.g., `ap-south-1`), and output format (e.g., `json`).

2. **Terraform**  
   - Install Terraform: [Terraform Installation Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli)

3. **Git**  
   - Install Git if not already available.

---

## Deployment Steps

1. **Clone the Repository**  
   ```bash
   git clone https://github.com/srhussain/DevOps-Project-Java-App-with-Terraform.git
   cd DevOps-Project-Java-App-with-Terraform/scripts


Run the Deployment Script

  ```bash
./deploy.sh


This script will:

Provision EC2 instances, VPC, and ALB using Terraform

Install Docker, Docker Compose, and AWS CLI on the EC2 instance

Start the application via Docker Compose

Set up the MySQL database and initialize it

Deploy the Java Login App via WAR file

Wait for Resources to Be Ready

ALB creation takes approximately 10–15 minutes.

Once the ALB is created, wait an additional 50–60 seconds for the application to start fully.

Access the Application

After the ALB is ready, access the application using the ALB DNS.

You can register yourself and then login using the credentials.

Don't forget to destory the resources just run
```bash
./destroy.sh
