#!/bin/bash
set -euo pipefail
LOG_PREFIX="[userdata]"

echo "$LOG_PREFIX Starting EC2 user-data script"

# ---------------------------
# 0. Update system and install dependencies
# ---------------------------
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y curl git lsof wget apt-transport-https ca-certificates gnupg software-properties-common unzip jq

# ---------------------------
# 1. Install AWS CLI v2
# ---------------------------
if ! command -v aws >/dev/null 2>&1; then
    echo "$LOG_PREFIX Installing AWS CLI v2"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    sudo /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
else
    echo "$LOG_PREFIX AWS CLI already installed"
fi

# ---------------------------
# 2. Install Docker
# ---------------------------
if ! command -v docker >/dev/null 2>&1; then
    echo "$LOG_PREFIX Installing Docker"
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sudo sh /tmp/get-docker.sh
    sudo usermod -aG docker ubuntu
    sudo systemctl enable docker
    sudo systemctl start docker
else
    echo "$LOG_PREFIX Docker already installed"
fi

# ---------------------------
# 3. Install Docker Compose
# ---------------------------
if ! command -v docker-compose >/dev/null 2>&1; then
    echo "$LOG_PREFIX Installing Docker Compose"
    DOCKER_COMPOSE_VERSION="2.27.0"
    sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    echo "$LOG_PREFIX Docker Compose already installed"
fi

# ---------------------------
# 4. Fetch DB credentials from SSM
# ---------------------------
echo "$LOG_PREFIX Fetching DB credentials from SSM"
# DB_USERNAME=$(aws ssm get-parameter --name "/loginapp/DB_USERNAME" --with-decryption --query "Parameter.Value" --output text)
# DB_PASSWORD=$(aws ssm get-parameter --name "/loginapp/DB_PASSWORD" --with-decryption --query "Parameter.Value" --output text)

DB_USERNAME="devops"
DB_PASSWORD="devops12345"
# ---------------------------
# 5. Create Docker network & volume
# ---------------------------
sudo docker network create java-login-app-net || true
sudo docker volume create java-login-app-db || true

# ---------------------------
# 6. Pull Docker images
# ---------------------------
sudo docker pull srdevop/java-login-app:v2
sudo docker pull mysql:8.0

# ---------------------------
# 7. Run MySQL container
# ---------------------------
sudo docker run -d \
  --name loginapp_db \
  --network java-login-app-net \
  -e MYSQL_ROOT_PASSWORD=rootpassword \
  -e MYSQL_DATABASE=UserDB \
  -e MYSQL_USER="$DB_USERNAME" \
  -e MYSQL_PASSWORD="$DB_PASSWORD" \
  -v java-login-app-db:/var/lib/mysql \
  mysql:8.0

# ---------------------------
# 8. Run Java app container
# ---------------------------
sudo docker run -d \
  --name loginapp_web \
  --network java-login-app-net \
  -e DB_USERNAME="$DB_USERNAME" \
  -e DB_PASSWORD="$DB_PASSWORD" \
  -e DB_HOST=loginapp_db \
  -e DB_PORT=3306 \
  -p 8080:8080 \
  srdevop/java-login-app:v2

echo "$LOG_PREFIX USERDATA SCRIPT COMPLETED"
