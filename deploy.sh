#!/bin/bash

# ASCII art with the name "Tharana Hansaja"
cat << "EOF"
  __  .__                                        .__                                      __        
_/  |_|  |__ _____ ____________    ____ _____    |  |__ _____    ____   ___________      |__|____   
\   __\  |  \\__  \\_  __ \__  \  /    \\__  \   |  |  \\__  \  /    \ /  ___/\__  \     |  \__  \  
 |  | |   Y  \/ __ \|  | \// __ \|   |  \/ __ \_ |   Y  \/ __ \|   |  \\___ \  / __ \_   |  |/ __ \_
 |__| |___|  (____  /__|  (____  /___|  (____  / |___|  (____  /___|  /____  >(____  /\__|  (____  /
           \/     \/           \/     \/     \/       \/     \/     \/     \/      \/\______|    \/ 
                                                                                          
EOF


# Update package lists
sudo apt update

# Install Apache
sudo apt install apache2 -y

# Disable default virtual host configuration
sudo a2dissite 000-default.conf
sudo systemctl reload apache2

# Install MySQL and set root password
sudo apt install mysql-server -y
sudo mysql_secure_installation

# Install PHP and required modules
sudo apt install php libapache2-mod-php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y

# Download and extract WordPress
sudo apt install wget -y
sudo wget -c http://wordpress.org/latest.tar.gz
sudo tar -xzvf latest.tar.gz
sudo mv wordpress /var/www/html/

# Set proper permissions
sudo chown -R www-data:www-data /var/www/html/wordpress
sudo chmod -R 755 /var/www/html/wordpress

# Create a virtual host configuration file
sudo cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/wordpress.conf
sudo sed -i 's#/var/www/html#/var/www/html/wordpress#g' /etc/apache2/sites-available/wordpress.conf
sudo a2ensite wordpress.conf
sudo systemctl reload apache2

# Create MySQL database and user for WordPress
wp_db=$WORDPRESS_DB_NAME
wp_user=$WORDPRESS_DB_USER
wp_password=$WORDPRESS_DB_PASSWORD

sudo mysql -u root -p <<MYSQL_SCRIPT
CREATE DATABASE $wp_db;
CREATE USER '$wp_user'@'localhost' IDENTIFIED BY '$wp_password';
GRANT ALL PRIVILEGES ON $wp_db.* TO '$wp_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Configure WordPress wp-config.php file
sudo cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sudo sed -i "s/database_name_here/$wp_db/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/username_here/$wp_user/g" /var/www/html/wordpress/wp-config.php
sudo sed -i "s/password_here/$wp_password/g" /var/www/html/wordpress/wp-config.php

# Install Certbot for Let's Encrypt SSL
sudo apt install certbot python3-certbot-apache -y

# Request SSL certificate
sudo certbot --apache

# Cleanup
sudo rm latest.tar.gz

echo "WordPress installation complete."
