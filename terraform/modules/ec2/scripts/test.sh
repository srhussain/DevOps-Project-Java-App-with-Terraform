sudo systemctl stop mysql && sudo apt purge -y mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-* && sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql && sudo deluser mysql && sudo delgroup mysql && sudo apt autoremove -y && sudo apt autoclean


#!/bin/bash
set -e

# -------------------------
# Update system
# -------------------------
apt update -y
apt upgrade -y

# -------------------------
# Install Java 8
# -------------------------
apt install -y openjdk-8-jdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# -------------------------
# Install Maven 3.8.7
# -------------------------
apt install -y maven

# -------------------------
# Install MySQL 8.0 (local)
# -------------------------
apt install -y mysql-server
systemctl enable mysql
systemctl start mysql

# -------------------------
# Fetch DB credentials from SSM
# -------------------------
db_username=$(aws ssm get-parameter --name "/dev/myapp/db_username" --query "Parameter.Value" --output text)
db_password=$(aws ssm get-parameter --name "/dev/myapp/db_password" --with-decryption --query "Parameter.Value" --output text)

export DB_USERNAME=$db_username
export DB_PASSWORD=$db_password

# -------------------------
# Set MySQL root password and create user
# -------------------------
mysql --execute="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_password}'; FLUSH PRIVILEGES;"
mysql --execute="CREATE USER IF NOT EXISTS '${db_username}'@'localhost' IDENTIFIED BY '${db_password}';"
mysql --execute="GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost'; FLUSH PRIVILEGES;"

# -------------------------
# Initialize Database from SQL file
# -------------------------
REPO_DIR="/home/ubuntu/DevOps-Project-Java-App-with-Terraform"
SQL_FILE="$REPO_DIR/terraform/ec2/scripts/db_init.sql"

if [ ! -d "$REPO_DIR" ]; then
    git clone https://github.com/srhussain/DevOps-Project-Java-App-with-Terraform.git "$REPO_DIR"
fi

if [ -f "$SQL_FILE" ]; then
    mysql -u ${db_username} -p${db_password} < "$SQL_FILE"
else
    echo "SQL file not found at $SQL_FILE"
fi

# -------------------------
# Install Tomcat 9.0.112
# -------------------------
cd /opt
wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.112/bin/apache-tomcat-9.0.112.tar.gz
tar -xvzf apache-tomcat-9.0.112.tar.gz
mv apache-tomcat-9.0.112 tomcat9
chmod +x /opt/tomcat9/bin/*.sh

# -------------------------
# Build Java Application with Maven
# -------------------------
APP_DIR="$REPO_DIR/Java-Login-App"
cd "$APP_DIR"
mvn clean install -DskipTests

# -------------------------
# Deploy WAR file to Tomcat
# -------------------------
WAR_FILE=$(ls "$APP_DIR/target"/*.war 2>/dev/null | head -n 1)
if [ -f "$WAR_FILE" ]; then
    cp "$WAR_FILE" /opt/tomcat9/webapps/
else
    echo "WAR file not found in $APP_DIR/target"
fi

# -------------------------
# Start Tomcat
# -------------------------
sh /opt/tomcat9/bin/startup.sh
