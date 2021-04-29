#!/bin/bash

# Update yum
sudo yum update -y

# Install LAMP Web Server on Amazon Linux 2
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd

# Install additional PHP repos
sudo yum install -y php-simplexml
sudo yum install -y php72-gd
sudo yum install -y php-pecl-imagick
sudo yum install -y php-mbstring

sudo systemctl restart php-fpm.service
sudo systemctl restart httpd.service
sudo systemctl enable httpd

# Install NFS packages
sudo apt install -y nfs-common

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

# Apache config and unset upgrade to HTTP/2
sudo echo "# file: /etc/httpd/conf.d/wordpress.conf
<VirtualHost *:80>
  Header unset Upgrade
  ServerName ${domain}
  ServerAlias ${domain}
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
sudo echo "# BEGIN WordPress
RewriteEngine On
RewriteBase /
RewriteRule ^index.php$ - [L]

# add a trailing slash to /wp-admin
RewriteRule ^wp-admin$ wp-admin/ [R=301,L]

RewriteCond %%{REQUEST_FILENAME} -f [OR]
RewriteCond %%{REQUEST_FILENAME} -d
RewriteRule ^ - [L]
RewriteRule ^(wp-(content|admin|includes).*) $1 [L]
RewriteRule ^(.*\.php)$ wp/$1 [L]
RewriteRule . index.php [L]
# END WordPress\
Options All -Indexes" >> /var/www/html/.htaccess

wp core download --allow-root

# Create WP config file
/usr/local/bin/wp config create --dbhost=${db_host} --dbname=${db_name} --dbuser=${db_user} --dbpass="${db_pass}" --allow-root --extra-php <<PHP
/** Detect if SSL is used. This is required since we are terminating SSL either on CloudFront or on ELB */
if ((\$_SERVER['HTTP_CLOUDFRONT_FORWARDED_PROTO'] == 'https') OR (\$_SERVER['HTTP_X_FORWARDED_PROTO'] == 'https'))
    {\$_SERVER['HTTPS']='on';}
define( 'WP_SITEURL', 'https://${domain}' );
define( 'WP_HOME', 'https://${domain}' );
define( 'TNA_CLOUD', false );
define( 'WP_ALLOW_MULTISITE', true );
define( 'MULTISITE', true );
define( 'SUBDOMAIN_INSTALL', true );
define( 'DOMAIN_CURRENT_SITE', '${domain}' );
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
PHP

# Reset .htaccess
/usr/local/bin/wp rewrite flush --allow-root 2>/var/www/html/wp-cli.log

sudo chown apache:apache /var/www -R
find /var/www -type d -exec chmod 775 {} \;
find /var/www -type f -exec chmod 664 {} \;

# Download TNA theme
mkdir /home/ec2-user/themes
curl -H "Authorization: token ${github_token}" -L https://github.com/nationalarchives/tna/archive/master.zip > /home/ec2-user/themes/tna.zip

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
/usr/local/bin/wp plugin install amazon-s3-and-cloudfront --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wordpress-seo --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wp-mail-smtp --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install jquery-colorbox --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install simple-footnotes --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install advanced-custom-fields --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install classic-editor --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install cms-tree-page-view --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install tablepress --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install tinymce-advanced --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install transients-manager --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wordpress-importer --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wp-smtp --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wp-super-cache --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-editorial-review/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-wp-aws/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-password-message/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/acf-flexible-content.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/acf-options-page.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/acf-repeater.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/advanced-custom-fields-code-area-field.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/post-tags-and-categories-for-pages.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://cdn.nationalarchives.gov.uk/wp-plugins/wds-active-plugin-data.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-profile-page/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-forms/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-newsletter/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/ds-tna-wp-ses/archive/refs/heads/main.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Rename TNA theme dir
sudo mv /var/www/html/wp-content/themes/tna-master /var/www/html/wp-content/themes/tna
