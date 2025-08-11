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

yum install epel-release vim unzip git -y  #

yum module disable mysql -y &>> $LOGFILE

VALIDATE $? "Disabling the default version"

git clone https://github.com/Sarthakx67/RoboShop-Shell-Script-For-Alma-Linux.git #

VALIDATE $? "Validate cloning of mongodb.sh"  #

cd /

cd /RoboShop-Shell-Script-For-Alma-Linux  #

VALIDATE $? "Validate cd to /RoboShop-Shell-Script-For-Alma-Linux"  #

cp /RoboShop-Shell-Script-For-Alma-Linux/03-mysql.repo /etc/yum.repos.d/mysql.repo &>> $LOGFILE

VALIDATE $? "Copying MySQL repo" 

yum install mysql-community-server -y &>> $LOGFILE

VALIDATE $? "Installing MySQL Server"

systemctl enable mysqld &>> $LOGFILE

VALIDATE $? "Enabling MySQL"

systemctl start mysqld &>> $LOGFILE

VALIDATE $? "Staring MySQL"

# Define the new password for easier management
NEW_ROOT_PASSWORD="RoboShop@1"
LOG_FILE="/var/log/mysqld.log"
PASSWORD_SEARCH_STRING="A temporary password is generated for root@localhost"

# Check if the log file exists and is readable
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: MySQL log file not found at $LOG_FILE."
    exit 1
fi

# Find the line with the temporary password and extract the password itself (the last word on the line)
TEMP_PASSWORD=$(grep "$PASSWORD_SEARCH_STRING" "$LOG_FILE" | awk '{print $NF}')

# Check if a temporary password was actually found in the log
if [ -n "$TEMP_PASSWORD" ]; then
  echo "Temporary root password found. Resetting password..."
  # Use the temporary password to log in and set the new permanent password
  mysql -u root --password="$TEMP_PASSWORD" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${NEW_ROOT_PASSWORD}';"
  
  # Check if the password change was successful
  if [ $? -ne 0 ]; then
      echo "Error: Failed to reset the MySQL root password."
      exit 1
  fi
  echo "Root password has been successfully updated."
else
  echo "Temporary password not found. Assuming password is set or not needed."
  # This part allows the script to continue if the password was already changed.
fi


# --- Part 2: Create Application Users ---

echo "Creating application users 'roboshop' and 'shipping'..."

# Use the new root password to execute the user creation commands.
# The SQL commands will create the user if it doesn't exist and grant privileges.
mysql -u root --password="${NEW_ROOT_PASSWORD}" -e " \
  CREATE USER 'roboshop'@'%' IDENTIFIED BY '${NEW_ROOT_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON *.* TO 'roboshop'@'%' WITH GRANT OPTION; \
  CREATE USER 'shipping'@'%' IDENTIFIED BY '${NEW_ROOT_PASSWORD}'; \
  GRANT ALL PRIVILEGES ON *.* TO 'shipping'@'%' WITH GRANT OPTION; \
  FLUSH PRIVILEGES;"

# Check if the user creation was successful
if [ $? -eq 0 ]; then
    echo "Successfully created and granted privileges to 'roboshop' and 'shipping' users."
else
    echo "Error: Failed to create application users."
    exit 1
fi