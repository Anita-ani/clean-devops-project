#!/bin/bash
yum update -y
yum install -y docker unzip
service docker start
usermod -aG docker ec2-user
systemctl enable docker

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 714926359346.dkr.ecr.eu-north-1.amazonaws.com

docker pull 714926359346.dkr.ecr.eu-north-1.amazonaws.com/flask-app:latest
docker run -d -p 5000:5000 714926359346.dkr.ecr.eu-north-1.amazonaws.com/flask-app:latest
