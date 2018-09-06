#!/usr/bin/env bash

# Download and Install the Latest Updates for the OS
sudo echo "Updating Server to Latest patches"
sudo apt-get update && sudo apt-get upgrade -y

##############################################################################################
##                          Update Certificate                                              ##
##############################################################################################
sudo echo "updating ssl certificate"
sudo cp /vagrantubuntu/*.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates


##############################################################################################
##                          DATABASE INSTALLATION                                           ##
##############################################################################################
# Set the Server Timezone to CST
sudo echo "Installing MySQL"
sudo echo "America/Chicago" > /etc/timezone
sudo dpkg-reconfigure -f noninteractive tzdata

# Install MySQL Server in a Non-Interactive mode. Default root password will be "root"
sudo echo "mysql-server-5.7 mysql-server/root_password password 123456789" | sudo debconf-set-selections
sudo echo "mysql-server-5.7 mysql-server/root_password_again password 123456789" | sudo debconf-set-selections
sudo apt-get -y install mysql-server-5.7

# Run the MySQL Secure Installation wizard
sudo chmod 777 /vagrantubuntu/secure.sh
sudo /vagrantubuntu/secure.sh

sudo sed -i 's/127\.0\.0\.1/0\.0\.0\.0/g' /etc/mysql/my.cnf
mysql -uroot -p123456789 -e 'USE mysql; UPDATE `user` SET `Host`="%" WHERE `User`="root" AND `Host`="localhost"; DELETE FROM `user` WHERE `Host` != "%" AND `User`="root"; FLUSH PRIVILEGES;'

sudo service mysql restart

##############################################################################################
##                          APACHE and PHP-FPM INSTALLATION                                 ##
##############################################################################################
sudo echo "Installing APACHE and PHP"
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y
sudo apt-get install php7.1 -y
sudo add-apt-repository ppa:ondrej/pkg-gearman -y
sudo apt-get update -y
sudo apt-get install -y php7.1-gearman php7.1-opcache php7.1-mysql php7.1-mbstring php7.1-mcrypt php7.1-zip php7.1-fpm php7.1-memcache php7.1-gd php7.1-curl php7.1-zip
sudo apt-get install -y php7.1-mbstring php7.1-memcache php7.1-memcached php7.1-pdo_mysql
sudo apt-get install -y php7.1-dom
sudo apt-get install -y php7.1-memcache php7.1-memcached

sudo apt-cache pkgnames | grep php7.1

echo "Start apache service"
sudo a2enmod ssl
sudo service apache2 restart

echo "ServerName localhost" | sudo tee /etc/apache2/conf-available/fqdn.conf && sudo a2enconf fqdn
sudo a2enmod rewrite
sudo a2enmod ssl

if [ -f /etc/php/7.1/apache2/php.ini ]; then
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.1/apache2/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.1/apache2/php.ini
fi


if [ ! -d /etc/apache2/ssl ]; then
    sudo mkdir /etc/apache2/ssl
    sudo openssl req -batch -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/apache2/ssl/apache.key -out /etc/apache2/ssl/apache.crt
fi

sudo echo "Restarting apache"
sudo service apache2 restart

cd ~
curl -O https://bootstrap.pypa.io/get-pip.py
python get-pip.py --user

echo "export PATH=~/.local/bin:$PATH" >> ~/.bash_profile
source ~/.bash_profile

echo "Install phpunit"
cd ~
sudo wget https://phar.phpunit.de/phpunit.phar
sudo chmod +x phpunit.phar
sudo mv phpunit.phar /usr/local/bin/phpunit

sudo locale-gen UTF-8

sudo a2dismod php5
sudo a2enmod php7.0

sudo echo "transfering .html and .php file"

sudo cp /vagrantubuntu/index.html /var/www/html/
sudo cp /vagrantubuntu/index.php /var/www/html/
sudo service apache2 restart

sudo bash /srv/www/deploy.sh

sudo update-rc.d apache2 enable


##############################################################################################
##                      PHP COMPOSER SETUP AND INSTALLATION                                 ##
##############################################################################################
echo "Checking composer..."
if [ ! -f /usr/local/bin/composer ]; then
  sudo curl -sS https://getcomposer.org/installer | php
  sudo mv ./composer.phar /usr/local/bin/composer
fi



##############################################################################################
##                     POPULATE DATABASE SCHEMA AND DATA TO MYSQL                           ##
##############################################################################################
# Download database schema
echo "Downloading a copy of the database (this may take a while)..."
cd ~
sudo cp /vagrantubuntu/*.sql ~

mysql -u root -p123456789 -e 'CREATE DATABASE test'


mysql -u root -p123456789 test < schema.sql
mysql -u root -p123456789 test < data.sql

echo "--- All done! ---"
echo "Add 127.0.0.1 testsite.samsung.local to your hosts file, and then open https://testsite.samsung.local in your browser."
echo ""

##############################################################################################
##                     Erase all file in perks                                              ##
##############################################################################################
sudo rm -rf /vagrantubuntu/
