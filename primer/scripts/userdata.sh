#!/bin/bash

# Update yum
sudo yum update -y

# Install apache
sudo yum install -y httpd httpd-tools mod_ssl
sudo systemctl enable httpd
sudo systemctl start httpd

# Install php 7.4
sudo amazon-linux-extras enable php7.4
sudo yum clean metadata
sudo yum install php php-common php-pear -y
sudo yum install php-{cli,cgi,curl,mbstring,gd,mysqlnd,gettext,json,xml,fpm,intl,zip,simplexml,gd} -y

# Install mysql5.7
sudo rpm -Uvh https://dev.mysql.com/get/mysql57-community-release-el7-11.noarch.rpm
sudo yum install mysql-community-server -y
sudo systemctl enable mysqld
sudo systemctl start mysqld

# Install ImageMagick
sudo yum -y install php-devel gcc ImageMagick ImageMagick-devel
sudo bash -c "yes '' | pecl install -f imagick"
sudo bash -c "echo 'extension=imagick.so' > /etc/php.d/imagick.ini"

sudo systemctl restart php-fpm.service
sudo systemctl restart httpd.service

# Install NFS packages
sudo yum install -y amazon-efs-utils
sudo yum install -y nfs-utils
sudo service nfs start
sudo service nfs status

# Install Cloudwatch agent
sudo yum install amazon-cloudwatch-agent -y
sudo amazon-linux-extras install -y collectd
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/cloudwatch/cloudwatch-agent-config.json /opt/aws/amazon-cloudwatch-agent/bin/config.json
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -s -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json

sudo /bin/dd if=/dev/zero of=/var/swap.1 bs=1M count=1024
sudo /sbin/mkswap /var/swap.1
sudo /sbin/swapon /var/swap.1s

# Install WP CLI
mkdir /build
cd /build
sudo curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wp cli info
cd /

cd /var/www/html
echo "<html><head><title>Health Check</title></head><body><h1>Hello world!</h1></body></html>" >> healthcheck.html
echo "apache_modules:
  - mod_rewrite" >> wp-cli.yml
if [[ "${environment}" == "live" ]]; then
    echo $"User-agent: *
Disallow: /wp-admin/
Allow: /wp-admin/admin-ajax.php" >> robots.txt
else
    echo $"User-agent: *
Disallow: /" >> robots.txt
    echo "<?php phpinfo() ?>" >> phpinfo.php
fi

if [[ "${environment}" == "dev" ]]; then
    sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/template-list.php /var/www/html/wp-content/uploads/templates.php
fi

# Apache config and unset upgrade to HTTP/2
sudo echo "# file: /etc/httpd/conf.d/wordpress.conf
<VirtualHost *:80>
  Header unset Upgrade
  ServerName ${int_siteurl}
  ServerAlias ${int_siteurl}
  ServerAdmin webmaster@nationalarchives.gov.uk
  DocumentRoot /var/www/html
  <Directory "/var/www/html">
    Options +FollowSymlinks
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>" >> /etc/httpd/conf.d/wordpress.conf
sudo systemctl restart httpd

# Create .htaccess
sudo echo "# BEGIN WordPress Multisite
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]

# add a trailing slash to /wp-admin
RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

RewriteCond %%{REQUEST_FILENAME} -f [OR]
RewriteCond %%{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) \$1 [L]
RewriteRule ^(.*\.php)$ \$1 [L]
RewriteRule . index.php [L]
# END WordPress
Options All -Indexes" >> /var/www/html/.htaccess

wp core download --allow-root

# Create WP config file
/usr/local/bin/wp config create --dbhost=${db_host} --dbname=${db_name} --dbuser=${db_user} --dbpass="${db_pass}" --allow-root --extra-php <<PHP
/* Turn HTTPS 'on' if HTTP_X_FORWARDED_PROTO matches 'https' */
\$headers = apache_request_headers();
if (isset(\$headers['HTTP_X_FORWARDED_PROTO']) &&  strpos(\$headers['HTTP_X_FORWARDED_PROTO'], 'https') !== false) {
    \$_SERVER['HTTPS'] = 'on';
}
define( 'PUBLIC_SITEURL', '${public_siteurl}' );
define( 'EDITOR_SITEURL', '${editor_siteurl}' );
define( 'INT_SITEURL', '${int_siteurl}' );
define( 'FORCE_SSL_ADMIN', false );
define( 'ADMIN_COOKIE_PATH', '/' );
define( 'COOKIEPATH', '/' );
define( 'SITECOOKIEPATH', '/' );
define( 'COOKIE_DOMAIN', 'nationalarchives.gov.uk' );
define( 'TEST_COOKIE', 'test_cookie' );
define( 'WP_ALLOW_MULTISITE', true );
define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', true );
define( 'DOMAIN_CURRENT_SITE', '${int_siteurl}' );
define( 'PATH_CURRENT_SITE', '/' );
define( 'SITE_ID_CURRENT_SITE', 1 );
define( 'BLOG_ID_CURRENT_SITE', 1 );
define( 'WP_MEMORY_LIMIT', '256M' );
define( 'WP_MAX_MEMORY_LIMIT', '2048M' );
define( 'SMTP_SES', true);
define( 'SMTP_SES_USER', '${ses_user}' );
define( 'SMTP_SES_PASS', '${ses_pass}' );
define( 'SMTP_SES_HOST', '${ses_host}' );
define( 'SMTP_SES_PORT', ${ses_port} );
define( 'SMTP_SES_SECURE', '${ses_secure}' );
define( 'SMTP_SES_FROM_EMAIL', '${ses_from_email}' );
define( 'SMTP_SES_FROM_NAME', '${ses_from_name}' );
@ini_set( 'upload_max_size' , '64M' );
@ini_set( 'post_max_size', '128M');
@ini_set( 'memory_limit', '256M' );

setcookie(TEST_COOKIE, 'WP Cookie check', 0, COOKIEPATH, COOKIE_DOMAIN);
if ( SITECOOKIEPATH != COOKIEPATH ) setcookie(TEST_COOKIE, 'WP Cookie check', 0, SITECOOKIEPATH, COOKIE_DOMAIN);
PHP

# Reset .htaccess
/usr/local/bin/wp rewrite flush --allow-root 2>/var/www/html/wp-cli.log

sudo chown apache:apache /var/www -R
find /var/www -type d -exec chmod 775 {} \;
find /var/www -type f -exec chmod 664 {} \;

# Download TNA theme and licensed plugins
mkdir /home/ec2-user/themes
curl -H "Authorization: token ${github_token}" -L https://github.com/nationalarchives/tna/archive/master.zip > /home/ec2-user/themes/tna.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/acf-flexible-content.zip ~/plugins/acf-flexible-content.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/acf-options-page.zip ~/plugins/acf-options-page.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/acf-repeater.zip ~/plugins/acf-repeater.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/advanced-custom-fields-code-area-field.zip ~/plugins/advanced-custom-fields-code-area-field.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/post-tags-and-categories-for-pages.zip ~/plugins/post-tags-and-categories-for-pages.zip
sudo aws s3 cp s3://${deployment_s3_bucket}/${service}/plugins/wds-active-plugin-data.zip ~/plugins/wds-active-plugin-data.zip

# Install themes
/usr/local/bin/wp theme install /home/ec2-user/themes/tna.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-base/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-about-us-foi/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-pressroom/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-home/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-contact/archive/develop.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/ds-wp-child-education/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-legal/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-labs/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-suffrage/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-ourrole/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/great-wharton-theme/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-latin/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-commercial-opportunities/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-black-history/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-design-guide/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-help-legal/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-get-involved/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-web-archive/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-domesday/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-about-us-research/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/ds-wp-child-about-us/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-re-using-psi/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-archives-inspire/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-about-us-jobs/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/ds-wp-child-information-management/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-first-world-war/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-cabinet-papers-100/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-base-child-stories-resource/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-about-us-commercial/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/ds-wp-child-help-with-your-research/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-currency-converter/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-base-long-form/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-research-redesign/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-archives-sector/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-child-portals/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Install plugins
/usr/local/bin/wp plugin install wordpress-seo --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install advanced-custom-fields --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install classic-editor --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install cms-tree-page-view --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install tablepress --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install tinymce-advanced --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install transients-manager --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wordpress-importer --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wp-super-cache --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/acf-flexible-content.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/acf-options-page.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/acf-repeater.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/advanced-custom-fields-code-area-field.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/post-tags-and-categories-for-pages.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install ~/plugins/wds-active-plugin-data.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-editorial-review/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-password-message/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-profile-page/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-forms/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-newsletter/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/ds-tna-wp-ses/archive/refs/heads/main.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/ds-tna-wp-aws/archive/refs/heads/main.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Rename TNA theme dir
sudo mv /var/www/html/wp-content/themes/tna-master /var/www/html/wp-content/themes/tna
