#!/bin/bash

# Update yum
sudo yum update -y

# Mount EFS storage
sudo mkdir -p ${mount_dir}
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${mount_target}:/ ${mount_dir}
sudo chmod 777 ${mount_dir}
cd ${mount_dir}
sudo chmod go+rw .
sudo ln -s /var/www/html ${mount_dir}
cd /

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

cd /var/www/html

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
# END WordPress" >> .htaccess

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
define( 'WPMS_ON', true );
@ini_set( 'upload_max_size' , '64M' );
@ini_set( 'post_max_size', '128M');
@ini_set( 'memory_limit', '256M' );
PHP

# Reset .htaccess
/usr/local/bin/wp rewrite flush --allow-root 2>/var/www/html/wp-cli.log

# Install themes
/usr/local/bin/wp theme install /home/ec2-user/themes/tna.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install /home/ec2-user/themes/tna-base.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Install plugins
/usr/local/bin/wp plugin install amazon-s3-and-cloudfront --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wordpress-seo --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install wp-mail-smtp --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-editorial-review/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-wp-aws/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-password-message/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Set file permissions for apache
sudo chown apache:apache /var/www/html -R
find /var/www/html -type d -exec chmod 775 {} \;
find /var/www/html -type f -exec chmod 664 {} \;
sudo systemctl restart httpd
