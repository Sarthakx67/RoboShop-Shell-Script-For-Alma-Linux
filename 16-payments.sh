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

yum install python36 gcc python3-devel -y &>>$LOGFILE

VALIDATE $? "Installing python"

USERNAME="roboshop"

if ! id "$USERNAME" &>/dev/null; then
    echo "Creating user '$USERNAME'..."
    useradd "$USERNAME"
    echo "User '$USERNAME' created successfully."
else
    echo "User '$USERNAME' already exists. Skipping creation."
fi

mkdir /app  &>>$LOGFILE

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>>$LOGFILE

VALIDATE $? "Downloading artifact"

cd /app &>>$LOGFILE

VALIDATE $? "Moving to app directory"

unzip /tmp/payment.zip &>>$LOGFILE

VALIDATE $? "unzip artifact"

pip3.6 install -r requirements.txt &>>$LOGFILE

VALIDATE $? "Installing dependencies"

cd /

git clone https://github.com/Sarthakx67/RoboShop-Shell-Script-For-Alma-Linux.git #

VALIDATE $? "Validate cloning of mongodb.sh"  #

cd /RoboShop-Shell-Script-For-Alma-Linux  #

VALIDATE $? "Validate cd to /RoboShop-Shell-Script-For-Alma-Linux"  #

VALIDATE $? "Installing dependencies"

cp /RoboShop-Shell-Script-For-Alma-Linux/15-payment.service /etc/systemd/system/payment.service &>>$LOGFILE

VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOGFILE

VALIDATE $? "daemon-reload"

systemctl enable payment  &>>$LOGFILE

VALIDATE $? "enable payment"

systemctl start payment &>>$LOGFILE

VALIDATE $? "starting payment"