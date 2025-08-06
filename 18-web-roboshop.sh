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

yum install nginx -y &>>$LOGFILE

VALIDATE $? "Installing Nginx"

systemctl enable nginx &>>$LOGFILE

VALIDATE $? "Enabling Nginx"

systemctl start nginx &>>$LOGFILE

VALIDATE $? "Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE

VALIDATE $? "Removing default index html files"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>>$LOGFILE

VALIDATE $? "Downloading web artifact"

cd /usr/share/nginx/html &>>$LOGFILE

VALIDATE $? "Moving to default HTML directory"

unzip /tmp/web.zip &>>$LOGFILE

VALIDATE $? "unzipping web artifact"

cd /  #

VALIDATE $? "changing directory"

git clone https://github.com/Sarthakx67/RoboShop-Shell-Script-For-Alma-Linux.git  #

VALIDATE $? "copying repo"

cp /RoboShop-Shell-Script-For-Alma-Linux/17-roboshop.conf  /etc/nginx/default.d/roboshop.conf &>>$LOGFILE  #

VALIDATE $? "copying roboshop config"

systemctl start nginx  &>>$LOGFILE

VALIDATE $? "starting Nginx"

systemctl restart nginx  &>>$LOGFILE

VALIDATE $? "Restarting Nginx"