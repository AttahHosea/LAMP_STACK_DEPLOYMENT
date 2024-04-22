#!/bin/bash

# Define variables for paths and IP address
LARAVEL_DIR="/var/www/html/laravel"
LARAVEL_CONF="/etc/apache2/sites-available/laravel.conf"
VIRTUAL_HOST="192.168.33.9"

# Update system packages
sudo apt update
sudo apt upgrade -y
echo "System packages updated."

# Add PHP repository
sudo add-apt-repository -y ppa:ondrej/php
echo "PHP repository added."

# Install Apache
sudo apt install -y apache2
sudo systemctl enable apache2
echo "Apache installed."

# Install MySQL with auto-configured root password
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo apt install -y mysql-server
echo "MySQL installed."

# Install PHP 8.2 and 8.3 with necessary extensions
sudo apt install -y php libapache2-mod-php php-mysql php8.2 php8.2-curl php8.2-dom php8.2-xml php8.2-mysql php8.2-sqlite3 php8.3 php8.3-curl php8.3-dom php8.3-xml php8.3-mysql php8.3-sqlite3
echo "PHP 8.2 and 8.3 installed with extensions."

# Secure MySQL installation
sudo mysql_secure_installation <<EOF

y
1
y
n
y
y
EOF
echo "MySQL secure installation completed."

# Restart Apache
sudo systemctl restart apache2
echo "Apache restarted."

# Install Git
sudo apt install -y git
echo "Git installed."

# Clone Laravel repository
sudo git clone https://github.com/laravel/laravel $LARAVEL_DIR
echo "Laravel repository cloned."

# Install Composer
sudo apt install -y composer
echo "Composer installed."

# Upgrade Composer to version 2
sudo php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
sudo php -r "if (hash_file('sha384', 'composer-setup.php') === 'dac665fdc30fdd8ec78b38b9800061b4150413ff2e3b6f88543c636f7cd84f6db9189d43a81e5503cda447da73c7e5b6') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
sudo php composer-setup.php --install-dir /usr/bin --filename composer
echo "Composer upgraded to version 2."

# Use Composer to install dependencies
yes | sudo composer install
echo "Composer dependencies installed."

# Copy and set permissions for Laravel configuration file
sudo cp .env.example .env
sudo chown www-data:www-data .env
sudo chmod 640 .env
echo "Laravel configuration file copied and permissions set."

# Create virtual host configuration for Apache
sudo tee $LARAVEL_CONF >/dev/null <<EOF
<VirtualHost *:80>
    ServerName $VIRTUAL_HOST
    ServerAlias *
    DocumentRoot $LARAVEL_DIR/public

    <Directory $LARAVEL_DIR>
        AllowOverride All
    </Directory>
</VirtualHost>
EOF
echo "Apache virtual host configuration created."

# Generate Laravel application key
sudo php artisan key:generate
echo "Laravel application key generated."

# Run database migrations
sudo php artisan migrate --force
echo "Database migrations completed."

# Change ownership and permissions
sudo chown -R www-data:www-data $LARAVEL_DIR/database/ $LARAVEL_DIR/storage/logs/ $LARAVEL_DIR/storage $LARAVEL_DIR/bootstrap/cache
sudo chmod -R 775 $LARAVEL_DIR/database/ $LARAVEL_DIR/storage/logs/ $LARAVEL_DIR/storage
echo "Ownership and permissions updated."

# Disable default Apache configuration
sudo a2dissite 000-default.conf
echo "Default Apache configuration disabled."

# Enable Laravel Apache configuration
sudo a2ensite laravel.conf
echo "Laravel Apache configuration enabled."

# Restart Apache
sudo systemctl restart apache2
echo "Apache restarted."

# Log server uptime
uptime > /var/log/uptime.log
echo "Server uptime logged."
