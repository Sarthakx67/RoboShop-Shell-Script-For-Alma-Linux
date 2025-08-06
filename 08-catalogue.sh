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

VALIDATE $? "installing important applications"

curl -sL https://rpm.nodesource.com/setup_lts.x | bash &>>$LOGFILE

VALIDATE $? "Setting up NPM Source"

yum install nodejs -y &>>$LOGFILE

VALIDATE $? "Installing NodeJS"

USERNAME="roboshop"

if ! id "$USERNAME" &>/dev/null; then
    echo "Creating user '$USERNAME'..."
    useradd "$USERNAME"
    echo "User '$USERNAME' created successfully."
else
    echo "User '$USERNAME' already exists. Skipping creation."
fi

mkdir /app &>>$LOGFILE

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>>$LOGFILE

VALIDATE $? "downloading catalogue artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving into app directory"

unzip /tmp/catalogue.zip &>>$LOGFILE

VALIDATE $? "unzipping catalogue"

npm install &>>$LOGFILE

git clone https://github.com/Sarthakx67/RoboShop-Shell-Script-For-Alma-Linux.git #

VALIDATE $? "Validate cloning of mongodb.sh"  #

cd /RoboShop-Shell-Script-For-Alma-Linux  #

VALIDATE $? "Validate cd to /RoboShop-Shell-Script-For-Alma-Linux"  #

VALIDATE $? "Installing dependencies"

cp /RoboShop-Shell-Script-For-Alma-Linux/07-catalogue.service  /etc/systemd/system/catalogue.service &>>$LOGFILE  #

VALIDATE $? "copying catalogue.service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon reload"

systemctl enable catalogue &>>$LOGFILE

VALIDATE $? "Enabling Catalogue"

systemctl start catalogue &>>$LOGFILE

VALIDATE $? "Starting Catalogue"

cp /RoboShop-Shell-Script-For-Alma-Linux/01-mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE   #

VALIDATE $? "Copying mongo repo"

cd /app

yum install mongodb-org-shell -y &>>$LOGFILE

VALIDATE $? "Installing mongo client"

mongo --host mongodb.stallions.space < /app/schema/catalogue.js &>>$LOGFILE   #

VALIDATE $? "loading catalogue data into mongodb"