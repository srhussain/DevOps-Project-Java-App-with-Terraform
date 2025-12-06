#!/bin/bash
set -euo pipefail
LOG_PREFIX="[userdata]"

echo "$LOG_PREFIX Starting user-data script"

export DEBIAN_FRONTEND=noninteractive
export PATH=$PATH:/usr/local/bin:/usr/bin

# ---------------------------
# 0. Basic updates + tools
# ---------------------------
echo "$LOG_PREFIX Updating system packages..."
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y unzip curl git lsof wget

# ---------------------------
# 1. Install AWS CLI v2
# ---------------------------
if ! command -v aws >/dev/null 2>&1; then
  echo "$LOG_PREFIX Installing AWS CLI v2..."
  cd /tmp
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  rm -rf /tmp/aws
  unzip -q awscliv2.zip
  sudo /tmp/aws/install --update
  sudo ln -sf /usr/local/bin/aws /bin/aws || true
else
  echo "$LOG_PREFIX AWS CLI already installed: $(aws --version 2>&1)"
fi

# ---------------------------
# 2. Install Java 8 and Maven
# ---------------------------
echo "$LOG_PREFIX Installing Java 8 and Maven..."
sudo apt install -y openjdk-8-jdk maven
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# ---------------------------
# 3. Install MySQL
# ---------------------------
echo "$LOG_PREFIX Installing MySQL..."
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql

# Wait for MySQL to be ready
echo "$LOG_PREFIX Waiting for MySQL service..."
for i in {1..10}; do
  if mysqladmin ping >/dev/null 2>&1; then
    break
  fi
  sleep 3
done

# ---------------------------
# 4. Fetch DB credentials from SSM
# ---------------------------
# SSM_USER_PARAM="/dev/myapp/db_username"
# SSM_PASS_PARAM="/dev/myapp/db_password"

# db_username="$(aws ssm get-parameter --name "$SSM_USER_PARAM" --query "Parameter.Value" --output text 2>/dev/null || true)"
# db_password="$(aws ssm get-parameter --name "$SSM_PASS_PARAM" --with-decryption --query "Parameter.Value" --output text 2>/dev/null || true)"

db_username="devops"
db_password="devops12345"

if [ -z "$db_username" ] || [ -z "$db_password" ]; then
  echo "$LOG_PREFIX ERROR: Could not fetch DB credentials from SSM. Exiting."
  exit 1
fi

echo "$LOG_PREFIX Got DB credentials from SSM (username hidden)"

# ---------------------------
# 5. Ensure MySQL root password / create app user
# ---------------------------
echo "$LOG_PREFIX Setting MySQL root password and app user..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_password}';
FLUSH PRIVILEGES;
CREATE USER IF NOT EXISTS '${db_username}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost';
FLUSH PRIVILEGES;
EOF

# ---------------------------
# 6. Clone repo and build
# ---------------------------
REPO_DIR="/home/ubuntu/DevOps-Project-Java-App-with-Terraform"
REPO_URL="https://github.com/srhussain/DevOps-Project-Java-App-with-Terraform.git"

echo "$LOG_PREFIX Cloning or updating repository..."
if [ ! -d "$REPO_DIR" ]; then
  sudo -u ubuntu git clone "$REPO_URL" "$REPO_DIR"
else
  sudo chown -R ubuntu:ubuntu "$REPO_DIR"
  sudo -u ubuntu git -C "$REPO_DIR" config --global --add safe.directory "$REPO_DIR"
  cd "$REPO_DIR" && sudo -u ubuntu git pull
fi

APP_DIR="$REPO_DIR/Java-Login-App"
if [ ! -d "$APP_DIR" ]; then
  echo "$LOG_PREFIX ERROR: Application folder not found: $APP_DIR"
  exit 1
fi

echo "$LOG_PREFIX Building Java app with Maven..."
sudo -u ubuntu mkdir -p /home/ubuntu/.m2
sudo chown -R ubuntu:ubuntu /home/ubuntu/.m2
cd "$APP_DIR"
sudo -u ubuntu mvn clean install -DskipTests

# ---------------------------
# 7. Install Tomcat
# ---------------------------
TOMCAT_DIR="/opt/tomcat9"
TOMCAT_VERSION="9.0.112"

if [ ! -d "$TOMCAT_DIR" ]; then
  cd /opt
  wget -q "https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
  tar -xzf "apache-tomcat-${TOMCAT_VERSION}.tar.gz"
  mv "apache-tomcat-${TOMCAT_VERSION}" tomcat9
  chmod +x /opt/tomcat9/bin/*.sh
fi

# Create tomcat user if not exists
if ! id -u tomcat >/dev/null 2>&1; then
  sudo useradd -r -m -U -d /opt/tomcat9 -s /bin/false tomcat || true
fi

# Pre-create necessary directories
sudo mkdir -p /opt/tomcat9/{logs,temp,work}
sudo chown -R tomcat:tomcat /opt/tomcat9
sudo chmod -R 755 /opt/tomcat9

# ---------------------------
# 8. Deploy WAR
# ---------------------------
WAR_FILE=$(ls "$APP_DIR/target"/*.war 2>/dev/null | head -n 1 || true)
if [ -z "$WAR_FILE" ]; then
  echo "$LOG_PREFIX ERROR: WAR not found in $APP_DIR/target"
  exit 1
fi

sudo rm -rf /opt/tomcat9/webapps/ROOT*
sudo cp "$WAR_FILE" /opt/tomcat9/webapps/ROOT.war
sudo chown tomcat:tomcat /opt/tomcat9/webapps/ROOT.war

# ---------------------------
# 9. Create systemd service
# ---------------------------
SERVICE_FILE="/etc/systemd/system/tomcat.service"

cat > /tmp/tomcat.service.tmp <<EOF
[Unit]
Description=Apache Tomcat 9 Web Application Server
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat

Environment="JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64"
Environment="DB_USERNAME=${db_username}"
Environment="DB_PASSWORD=${db_password}"
Environment="CATALINA_OPTS=-DDB_USERNAME=${db_username} -DDB_PASSWORD=${db_password}"
Environment="CATALINA_PID=/opt/tomcat9/temp/tomcat.pid"

ExecStart=/opt/tomcat9/bin/startup.sh
ExecStop=/opt/tomcat9/bin/shutdown.sh

Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo mv /tmp/tomcat.service.tmp "$SERVICE_FILE"
sudo chmod 644 "$SERVICE_FILE"

sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl restart tomcat

# ---------------------------
# 10. Logs + completion
# ---------------------------
sleep 5
sudo systemctl status tomcat --no-pager -l
if [ -f /opt/tomcat9/logs/catalina.out ]; then
  sudo tail -n 50 /opt/tomcat9/logs/catalina.out
else
  echo "$LOG_PREFIX catalina.out not present; check 'journalctl -u tomcat'"
  sudo journalctl -u tomcat -n 80 --no-pager || true
fi

echo "$LOG_PREFIX USERDATA SCRIPT COMPLETED"
