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

dnf install maven -y

useradd roboshop

mkdir /app

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip

cd /app

unzip /tmp/shipping.zip

mvn clean package

mv target/shipping-1.0.jar shipping.jar

mv shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload

systemctl enable shipping 

systemctl start shipping

dnf install mysql -y

mysql -h mysql.dawsmani.site -uroot -pRoboShop@1 < /app/schema/shipping.sql 

systemctl restart shipping

# There is some issue with the shipping.sql schema file. Here is the solution for the same:
# Please replace line 26 with these 3 lines in your /app/schema/shipping.sql file
#   CREATE USER IF NOT EXISTS 'shipping'@'%' IDENTIFIED WITH mysql_native_password BY 'RoboShop@1';
#   GRANT ALL ON cities.* TO 'shipping'@'%';
#   FLUSH PRIVILEGES;