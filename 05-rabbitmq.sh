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

curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>>$LOGFILE

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>>$LOGFILE

yum install rabbitmq-server -y  &>>$LOGFILE

systemctl enable rabbitmq-server  &>>$LOGFILE

systemctl start rabbitmq-server  &>>$LOGFILE

rabbitmqctl add_user roboshop roboshop123 &>>$LOGFILE

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOGFILE