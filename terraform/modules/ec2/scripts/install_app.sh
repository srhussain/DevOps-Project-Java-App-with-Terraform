#!/bin/bash
set -e

# ============================================================
# 1. Update System Packages
# ============================================================
echo "[INFO] Updating system packages..."
sudo apt update -y
sudo apt upgrade -y

echo "[INFO] Installing/Updating AWS CLI v2..."

sudo apt install -y unzip

cd /tmp

# Download AWS CLI
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Remove old extracted folder if exists
rm -rf /tmp/aws

unzip -q awscliv2.zip

# Install or Update
if [ -d "/usr/local/aws-cli" ]; then
    echo "[INFO] AWS CLI already installed. Updating..."
    sudo ./aws/install --update
else
    echo "[INFO] AWS CLI not found. Installing fresh..."
    sudo ./aws/install
fi

# Ensure PATH is updated
export PATH=$PATH:/usr/local/bin:/usr/bin

echo "[INFO] AWS CLI installation/update completed."
aws --version

# ============================================================
# 2. Install Java 8
# ============================================================
echo "[INFO] Installing Java 8..."
sudo apt install -y openjdk-8-jdk
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH

# ============================================================
# 3. Install Maven
# ============================================================
echo "[INFO] Installing Maven..."
sudo apt install -y maven

# ============================================================
# 4. Install MySQL Server
# ============================================================
echo "[INFO] Installing MySQL Server..."
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql

# ============================================================
# 5. Database Credentials
# Replace with SSM later if needed

db_username=$(aws ssm get-parameter --name "/dev/myapp/db_username" --query "Parameter.Value" --output text)
db_password=$(aws ssm get-parameter --name "/dev/myapp/db_password" --with-decryption --query "Parameter.Value" --output text)

# ============================================================

# if you dont want to use aws SSM then use  this locally but not a good practise

# db_username="devops"
# db_password="devops12345"


# ============================================================
# 6. Fix MySQL Root Password (Ubuntu 24.04 fix)
# ============================================================
echo "[INFO] Fixing MySQL root password..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${db_password}';
FLUSH PRIVILEGES;
EOF

echo "[INFO] Creating DB user if not exists..."
sudo mysql -uroot -p${db_password} <<EOF
CREATE USER IF NOT EXISTS '${db_username}'@'localhost' IDENTIFIED BY '${db_password}';
GRANT ALL PRIVILEGES ON *.* TO '${db_username}'@'localhost';
FLUSH PRIVILEGES;
EOF

# ============================================================
# 7. Clone Application Repository
# ============================================================
REPO_DIR="/home/ubuntu/DevOps-Project-Java-App-with-Terraform"
if [ ! -d "$REPO_DIR" ]; then
    echo "[INFO] Cloning repository..."
    git clone https://github.com/srhussain/DevOps-Project-Java-App-with-Terraform.git "$REPO_DIR"
else
    echo "[INFO] Repository already exists. Pulling latest changes..."
    cd "$REPO_DIR"
    git pull
fi

# ============================================================
# 8. Initialize Database (only if SQL file exists)
# ============================================================
SQL_FILE="$REPO_DIR/terraform/modules/ec2/scripts/db_init.sql"
if [ -f "$SQL_FILE" ]; then
    echo "[INFO] Initializing database..."
    # Check if database exists to avoid duplicate error
    DB_NAME=$(grep -i "CREATE DATABASE" "$SQL_FILE" | awk '{print $3}' | tr -d ';')
    EXISTS=$(sudo mysql -uroot -p${db_password} -e "SHOW DATABASES LIKE '$DB_NAME';" | grep "$DB_NAME" || true)
    if [ -z "$EXISTS" ]; then
        sudo mysql -uroot -p${db_password} < "$SQL_FILE"
        echo "[INFO] Database initialized."
    else
        echo "[INFO] Database '$DB_NAME' already exists. Skipping initialization."
    fi
else
    echo "[WARN] SQL file not found at $SQL_FILE"
fi

# ============================================================
# 9. Install Tomcat 9
# ============================================================
TOMCAT_DIR="/opt/tomcat9"
if [ ! -d "$TOMCAT_DIR" ]; then
    echo "[INFO] Installing Tomcat 9..."
    cd /opt
    sudo wget https://dlcdn.apache.org/tomcat/tomcat-9/v9.0.112/bin/apache-tomcat-9.0.112.tar.gz
    sudo tar -xvzf apache-tomcat-9.0.112.tar.gz
    sudo mv apache-tomcat-9.0.112 tomcat9
    sudo chmod +x /opt/tomcat9/bin/*.sh
else
    echo "[INFO] Tomcat already installed."
fi

# ============================================================
# 10. Build Java Application with Maven
# ============================================================
APP_DIR="$REPO_DIR/Java-Login-App"
if [ -d "$APP_DIR" ]; then
    echo "[INFO] Building Java application..."
    cd "$APP_DIR"
    mvn clean install -DskipTests
else
    echo "[ERROR] Application directory not found: $APP_DIR"
    exit 1
fi

# ============================================================
# 11. Deploy WAR File to Tomcat
# ============================================================
WAR_FILE=$(ls "$APP_DIR/target"/*.war 2>/dev/null | head -n 1)
if [ -f "$WAR_FILE" ]; then
    echo "[INFO] Cleaning old WAR and expanded folders..."
    sudo rm -rf /opt/tomcat9/webapps/ROOT*


    echo "[INFO] Deploying WAR file to Tomcat..."
    sudo cp -r "$WAR_FILE" /opt/tomcat9/webapps/ROOT.war
else
    echo "[WARN] WAR file not found in $APP_DIR/target"
fi


export DB_USERNAME=$db_username
export DB_PASSWORD=$db_password

# 11.1 Create setenv.sh to pass DB credentials to Tomcat
# ============================================================
echo "[INFO] Creating Tomcat setenv.sh to pass DB credentials..."
SETENV_FILE="/opt/tomcat9/bin/setenv.sh"

sudo tee $SETENV_FILE > /dev/null <<EOF
#!/bin/bash
export DB_USERNAME=$db_username
export DB_PASSWORD=$db_password
CATALINA_OPTS="\$CATALINA_OPTS -DDB_USERNAME=\$DB_USERNAME -DDB_PASSWORD=\$DB_PASSWORD"
export CATALINA_OPTS
EOF

sudo chmod +x $SETENV_FILE


# ============================================================
# 12. Start Tomcat
# ============================================================
echo "[INFO] Starting Tomcat..."
sudo sh /opt/tomcat9/bin/shutdown.sh
sudo sh /opt/tomcat9/bin/startup.sh



echo "============================================================"
echo "   Application deployment completed successfully! 🎉"
echo "============================================================"