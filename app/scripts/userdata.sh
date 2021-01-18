#!/bin/bash

# Update yum
sudo yum update -y

# Mount EFS storage
sudo mkdir -p ${mount_dir}
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${mount_target}:/ ${mount_dir}
sudo chmod 777 ${mount_dir}
cd ${mount_dir}
sudo chmod go+rw .
cd /

# Auto mount EFS storage on reboot
sudo echo "${mount_target}:/ ${mount_dir} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,fsc,_netdev 0 0" >> /etc/fstab

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
sudo mv /var/www/html/wp-content/themes/tna-master /var/www/html/wp-content/themes/tna
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
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-long-form-template-BT/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp theme install https://github.com/nationalarchives/tna-research-redesign/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log

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
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-eventbrite-api/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-forms/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log
/usr/local/bin/wp plugin install https://github.com/nationalarchives/tna-newsletter/archive/master.zip --force --allow-root 2>/var/www/html/wp-cli.log

# Link uploads directory to EFS
sudo mkdir -p /mnt/efs/uploads
sudo rm -rf /var/www/html/wp-content/uploads
sudo ln -snf /mnt/efs/uploads /var/www/html/wp-content/uploads

# Set file permissions for apache
sudo chown apache:apache /var/www/html -R
find /var/www/html -type d -exec chmod 775 {} \;
find /var/www/html -type f -exec chmod 664 {} \;
sudo systemctl restart httpd
