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
if [ $? -ne 0 ]
then 
    useradd roboshop &>>$LOGFILE
    VALIDATE $? "Roboshop useradded"
else
    echo -e "User Already Exists... $Y SKIPPING $N"
fi

rm -rf /app &>> $LOGFILE
VALIDATE $? "Cleaning up existing directory"

mkdir -p /app &>>$LOGFILE
VALIDATE $? "app directory created"

curl -L -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip &>>$LOGFILE
VALIDATE $? "Downloded Application code to created directory"

cd /app &>>$LOGFILE
VALIDATE $? "Iam in app directory"

unzip /tmp/cart.zip &>>$LOGFILE
VALIDATE $? "Unzipping in tmp folder"

cd /app &>>$LOGFILE
VALIDATE $? "In app directory"

npm install &>>$LOGFILE
VALIDATE $? "Installing npm"

cp /home/ec2-user/roboshop-shell/cart.service /etc/systemd/system/cart.service &>>$LOGFILE
VALIDATE $? "Setup of SystemD Cart Service"

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon-Reloaded"

systemctl enable catalogue &>>$LOGFILE
VALIDATE $? "Enabled cart"

systemctl start catalogue &>>$LOGFILE
VALIDATE $? "Starting cart"