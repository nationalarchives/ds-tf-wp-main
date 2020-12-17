#!/bin/bash

# Update yum
sudo yum update -y

# Mount EFS storage
sudo mkdir -p ${mount_dir}
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${mount_target}:/ ${mount_dir}
sudo chmod 777 ${mount_dir}
cd ${mount_dir}
sudo chmod go+rw .
sudo ln -s /var/nationalarchives.gov.uk ${mount_dir}
cd /

# Install nginx
sudo amazon-linux-extras install -y nginx1

sudo systemctl enable --now nginx

# Copy configuration file
sudo aws s3 cp s3://tna-dev-deployment/main-wp/nginx-configs/nginx.conf /etc/nginx/nginx.conf

# Restart nginx to reload new config file
sudo systemctl restart nginx
