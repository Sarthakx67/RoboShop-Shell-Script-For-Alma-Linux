#!/bin/bash

DATE=$(date +%F)
LOGSDIR=/tmp

# Use basename to get just the script's filename
SCRIPT_NAME=$(basename $0)
LOGFILE=$LOGSDIR/$SCRIPT_NAME-$DATE.log
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

if [ $USERID -ne 0 ];
then
    echo -e "$R ERROR:: Please run this script with root access $N"
    exit 1
fi

VALIDATE(){
    if [ $1 -ne 0 ];
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}
setenforce 0  #

MYSQL_HOST="mysql.stallions.space"
CART_HOST="cart.app.stallions.space"
APP_USER="roboshop"
APP_DIR="/app"
NEW_DB_PASS="RoboShop@1" # Password for application users

# --- Task: Install prerequisite packages ---
echo "--> Installing prerequisite packages: EPEL, Maven, MySQL client..."
yum install -y epel-release maven mysql 

# --- Task: Create Roboshop application user ---
echo "--> Creating application user '$APP_USER'..."
# This command creates a system user only if it doesn't already exist.
id -u $APP_USER &>/dev/null || useradd -r -s /bin/nologin $APP_USER

# --- Task: Ensure /app directory exists ---
echo "--> Creating application directory '$APP_DIR'..."
mkdir -p "$APP_DIR"
chown "$APP_USER:$APP_USER" "$APP_DIR"

# --- Task: Download and unpack shipping artifact ---
echo "--> Downloading and unpacking shipping application..."
# We use a temporary file for the download to keep things clean.
curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip
# Unzip into the app directory, overwriting existing files if any.
unzip -o /tmp/shipping.zip -d "$APP_DIR"
# Ensure all extracted files are owned by the application user.
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
# Clean up the downloaded zip file.
rm -f /tmp/shipping.zip

# --- Task: Build application with Maven ---
echo "--> Building application with Maven (this may take a moment)..."
# We run the build command from within the application directory.
(cd "$APP_DIR" && mvn clean package)

# --- Task: Create shipping systemd service file ---
echo "--> Creating systemd service file for shipping..."
# Using a 'here document' to write the multi-line service file.
cat > /etc/systemd/system/shipping.service <<EOF
[Unit]
Description=Shipping Service

[Service]
User=${APP_USER}
Environment="CART_ENDPOINT=${CART_HOST}:80"
Environment="DB_HOST=${MYSQL_HOST}"
Environment="DB_USER=shipping"
Environment="DB_PASS=${NEW_DB_PASS}"
ExecStart=/usr/bin/java -jar ${APP_DIR}/target/shipping-1.0.jar
SyslogIdentifier=shipping

[Install]
WantedBy=multi-user.target
EOF

# --- Simplified Database Block ---
# Note: These commands ignore errors, just like the Ansible playbook.
# This is useful in case the schema or data has already been loaded.

echo "--> Loading application database schema..."
mysql -h "${MYSQL_HOST}" -u"${APP_USER}" -p"${NEW_DB_PASS}" < "${APP_DIR}/db/schema.sql" 2>/dev/null

echo "--> Renaming 'cities' table to 'codes'..."
mysql -h "${MYSQL_HOST}" -u"${APP_USER}" -p"${NEW_DB_PASS}" cities -e 'RENAME TABLE cities TO codes;' 2>/dev/null

echo "--> Loading master data into the database..."
mysql -h "${MYSQL_HOST}" -u"${APP_USER}" -p"${NEW_DB_PASS}" cities < "${APP_DIR}/db/master-data.sql" 2>/dev/null

# --- Handler: Reload and restart shipping ---
echo "--> Reloading systemd, enabling and restarting the shipping service..."
systemctl daemon-reload
systemctl enable shipping
systemctl restart shipping

echo ">>> Shipping Service installation and configuration complete!"