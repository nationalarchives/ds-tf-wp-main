#!/bin/bash

# Update yum
sudo yum update -y

# Mount EFS storage
sudo mkdir -p /mnt/efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 fs-051b2ef4.efs.eu-west-2.amazonaws.com:/ /mnt/efs
sudo chmod 777 /mnt/efs
cd /mnt/efs
sudo chmod go+rw .
cd /

# Link directory to EFS mount directory
sudo ln -snf /mnt/efs /var/nationalarchives.gov.uk

# Auto mount EFS storage on reboot
sudo echo "fs-051b2ef4.efs.eu-west-2.amazonaws.com:/ /mnt/efs nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,fsc,_netdev 0 0" >> /etc/fstab

# Copy configuration files
sudo aws s3 cp s3://${s3_deployment_bucket}/${s3_deployment_root}/nginx/nginx.conf /etc/nginx/nginx.conf
sudo aws s3 cp s3://${s3_deployment_bucket}/${s3_deployment_root}/nginx/admin_ips.conf /etc/nginx/admin_ips.conf
sudo aws s3 cp s3://${s3_deployment_bucket}/${s3_deployment_root}/nginx/wp_admin.conf /etc/nginx/wp_admin.conf
sudo aws s3 cp s3://${s3_deployment_bucket}/${s3_deployment_root}/nginx/wp_admin_subdomain.conf /etc/nginx/wp_admin_subdomain.conf

# install all tools required for nginx compilation
# please update the version for nginx to the lastest stable version
sudo yum install -y git
sudo yum install -y pcre-devel zlib-devel openssl-devel gcc gcc-c++ make
sudo yum install -y system-rpm-config
sudo yum install -y wget openssl-devel libxml2-devel libxslt-devel gd-devel
sudo yum install -y perl-ExtUtils-Embed GeoIP-devel gperftools gperftools-devel libatomic_ops-devel

sudo curl -O http://nginx.org/download/nginx-1.21.0.tar.gz
sudo tar -xvf nginx-1.21.0.tar.gz
sudo rm nginx-1.21.0.tar.gz
cd nginx-1.21.0/
sudo git clone https://github.com/yaoweibin/ngx_http_substitutions_filter_module.git
sudo ./configure --prefix=/usr/share/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --http-client-body-temp-path=/var/lib/nginx/tmp/client_body --http-proxy-temp-path=/var/lib/nginx/tmp/proxy --http-fastcgi-temp-path=/var/lib/nginx/tmp/fastcgi --http-uwsgi-temp-path=/var/lib/nginx/tmp/uwsgi --http-scgi-temp-path=/var/lib/nginx/tmp/scgi --pid-path=/run/nginx.pid --lock-path=/run/lock/subsys/nginx --user=nginx --group=nginx --with-compat --with-file-aio --with-http_ssl_module --with-http_v2_module --with-http_realip_module --with-stream_ssl_preread_module --with-http_addition_module --with-http_xslt_module=dynamic --with-http_image_filter_module=dynamic --with-http_geoip_module=dynamic --with-http_sub_module --with-http_dav_module --with-http_flv_module --with-http_mp4_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_random_index_module --with-http_secure_link_module --with-http_degradation_module --with-http_slice_module --with-http_stub_status_module --with-http_perl_module=dynamic --with-http_auth_request_module --with-mail=dynamic --with-mail_ssl_module --with-pcre --with-pcre-jit --with-stream=dynamic --with-stream_ssl_module --with-google_perftools_module --with-debug --with-cc-opt='-O2 -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fexceptions -fstack-protector-strong --param=ssp-buffer-size=4 -grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -m64 -mtune=generic' --with-ld-opt='-Wl,-z,relro -specs=/usr/lib/rpm/redhat/redhat-hardened-ld -Wl,-E' --add-module=./ngx_http_substitutions_filter_module
sudo make
sudo make install

sudo groupadd nginx
sudo useradd -c "Nginx web server" -g nginx -d /var/lib/nginx -s /sbin/nologin nginx

sudo mkdir /var/lib/nginx
sudo mkdir /var/lib/nginx/tmp
sudo mkdir /var/lib/nginx/tmp/client_body
sudo mkdir /var/lib/nginx/tmp/fastcgi
sudo mkdir /var/lib/nginx/tmp/proxy
sudo mkdir /var/lib/nginx/tmp/scgi
sudo mkdir /var/lib/nginx/tmp/uwsgi

sudo chown -R nginx /var/lib/nginx/
sudo chown -R nginx /var/log/nginx/

# prepare nginx as service
sudo cat << EOF > ~/nginx.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

sudo cp ~/nginx.service /lib/systemd/system/nginx.service

sudo systemctl enable nginx
sudo sytemctl start nginx
