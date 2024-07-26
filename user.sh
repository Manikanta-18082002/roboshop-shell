#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
   if [ $1 -ne 0 ]
   then
        echo -e "$2...$R FAILURE $N"
        exit 1
    else
        echo -e "$2...$G SUCCESS $N"
    fi
}

if [ $USERID -ne 0 ]
then
    echo "Please run this script with root access."
    exit 1 # manually exit if error comes.
else
    echo "You are super user."
fi

dnf module disable nodejs -y &>>$LOGFILE
VALIDATE $? "Nodejs Disabled"

dnf module enable nodejs:20 -y &>>$LOGFILE
VALIDATE $? "Enabled nodejs 20"

dnf install nodejs -y &>>$LOGFILE
VALIDATE $? "Installed Nodejs"

id roboshop &>>$LOGFILE
if [ $? -ne]

useradd roboshop &>>$LOGFILE
VALIDATE $? "Roboshop useradded"

mkdir /app &>>$LOGFILE
VALIDATE $? "app directory created"

curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>>$LOGFILE
VALIDATE $? "Downloded Application code to created directory"

cd /app &>>$LOGFILE
VALIDATE $? "Iam in app directory"

unzip /tmp/user.zip &>>$LOGFILE
VALIDATE $? "Unzipping in tmp folder"

cd /app &>>$LOGFILE
VALIDATE $? "In app directory"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm"

cp user.service /etc/systemd/system/user.service &>>$LOGFILE
VALIDATE $? "Setup of SystemD user Service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon-Reloaded"

systemctl enable catalogue &>>$LOGFILE
VALIDATE $? "Enabled user"

systemctl start catalogue &>>$LOGFILE
VALIDATE $? "start user"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE
VALIDATE $? "Copied Mongo repo"

dnf install -y mongodb-mongosh &>>$LOGFILE
VALIDATE $? "Installed mongosh"

mongosh --host mongodb.dawsmani.site </app/schema/catalogue.js &>>$LOGFILE
VALIDATE $? "Loading Schema"