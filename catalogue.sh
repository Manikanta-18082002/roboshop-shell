#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGFILE=/tmp/$SCRIPT_NAME-$TIMESTAMP.log
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
MONGO_HOST=mongodb.dawsmani.site

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
VALIDATE $? "Installing Nodejs"

id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
    useradd roboshop &>> $LOGFILE
    VALIDATE $? "Adding roboshop user"
else
    echo -e "Roboshop user already exist...$Y SKIPPING $N"
fi


rm -rf /app &>>$LOGFILE
VALIDATE $? "Clean up existing library"

mkdir -p /app &>>$LOGFILE # -p: if not exist create else skip
VALIDATE $? "app directory created"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip &>>$LOGFILE
VALIDATE $? "Downloded Application code to created directory"

cd /app &>>$LOGFILE
VALIDATE $? "Iam in app directory"

unzip /tmp/catalogue.zip &>>$LOGFILE
VALIDATE $? "Unzipping in tmp folder"

cd /app &>>$LOGFILE
VALIDATE $? "In app directory"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm"

cp /home/ec2-user/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service &>>$LOGFILE
VALIDATE $? "Setup of System Catalogue Service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon-Reloaded"

systemctl enable catalogue &>>$LOGFILE
VALIDATE $? "Enabled catalogue"

systemctl start catalogue &>>$LOGFILE
VALIDATE $? "start catalogue"

cp /home/ec2-user/roboshop-shell/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOGFILE
VALIDATE $? "Copied Mongo repo"

dnf install -y mongodb-mongosh &>>$LOGFILE
VALIDATE $? "Installed mongo Client"

SCHEMA_EXISTS=$(mongosh --host $MONGO_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')") &>> $LOGFILE

if [ $SCHEMA_EXISTS -lt 0 ] # -1: not there 0: exists
then
    echo "Schema does not exists ... LOADING"
    mongosh --host $MONGO_HOST </app/schema/catalogue.js &>> $LOGFILE
    VALIDATE $? "Loading catalogue data"
else
    echo -e "Schema already exists... $Y SKIPPING $N"
fi