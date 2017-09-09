# Do -NOT- run this as a script!!! Only a .sh file to utilize
# syntax highlighting in a text editor for easier readability
# NOTE: stemroi/conf/000-default.conf and stemroi/conf/default-ssl.conf are
# for backup purposes only (their content is a result of these instructions).

# Ubuntu Server 16.04.3 README/INSTALL for stemroi
# See https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-16-04
# DigitalOcean IP: 165.227.17.32

# Make user account and grant sudo (not required locally)
# NOTE: The rest of this file assumes all commands are run as root (sudo su -)
sudo su -
adduser <username>
usermod -aG sudo <username>

# Update the OS - it will also update Python 3 to Python 3.5.2
apt-get update && apt-get -y upgrade

# ******************************* LOCAL ONLY *******************************
# Configure 2nd network card (for easy local SSH access)
vi /etc/network/interfaces
auto enp0s8
iface enp0s8 inet static
address 10.83.33.5
netmask 255.255.255.0
# Install the following packages for VirtualBox Guest Additions
apt-get install -y dkms build-essential linux-headers-generic linux-headers-$(uname -r)
# Reboot, then add users to vboxsf
usermod -aG vboxsf <username>
# Install OpenSSL
# apt-get install -y wget nmap lsof tcpdump git
# **************************************************************************

# Install pip
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-python-3-and-set-up-a-local-programming-environment-on-ubuntu-16-04
apt-get install -y python3-pip

# From the above link: " ensure that we have a robust set-up for our
# programming environment"
apt-get install build-essential libssl-dev libffi-dev python3-dev

# Install Apache and mod_wsgi - this will auto-configure mod_wsgi in Apache
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-16-04 for Apache install
apt-get -y install apache2 libapache2-mod-wsgi-py3 python3-setuptools

# See /usr/share/doc/apache2/README.Debian.gz on how to configure SSL
# and create self-signed certificates (this is just informative--we will user
# Let's Encrypt for SSL certs later in this file).
# Enable mod_ssl
a2enmod ssl
# Enable mod_rewrite
# Source: https://www.digitalocean.com/community/tutorials/how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-16-04
a2enmod rewrite
# Enable mod_headers
# Source: https://serverfault.com/questions/848615/installation-of-mod-headers-c-not-successful
a2enmod headers

# Install MySQL
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-mysql-on-ubuntu-16-04
apt-get install -y mysql-server libmysqlclient-dev
# This will cause a package configuration window to show up that makes you
# create a MySQL root password

# Clone stemroi GitHub repo (username@ is required)
cd /var/www
git clone https://jsilber@github.com/jsilber/stemroi.git
# Install dependencies
cd /var/www/stemroi
pip3 install -r requirements.txt
# Change permissions for Apache
chown -R www-data:www-data stemroi
# WARNING: Change MySQL root password in stemroi.py!!!

# Run the following to secure MySQL:
mysql_secure_installation
# You will get prompted for the following (answers as configured
# after the colon):
Press y|Y for Yes, any other key for No: n
Change the password for root ? (Press y|Y for Yes, any other key for No) : n
Remove anonymous users? (Press y|Y for Yes, any other key for No) : y
Disallow root login remotely? (Press y|Y for Yes, any other key for No) : y
Remove test database and access to it? (Press y|Y for Yes, any other key for No) : y
Reload privilege tables now? (Press y|Y for Yes, any other key for No) : y

# Login to mysql
mysql -u root -p
# Drop existing database (if necessary)
mysql> drop database if exists stemroidb;
# Create initial database
mysql> create database stemroidb;
# Exit mysql client and load stemroi_mysql.sql
mysql -u root -p < stemroi_mysql.sql
# Log back in to mysql
mysql -u root -p
# List installed databases
mysql> show databases;
# Switch to stemroidb
mysql> use stemroidb;
# Confirm tables
mysql> show tables;
# Confirm stored procedure(s)
mysql> show create procedure averages_by_state;

# Allow Apache and SSH through the Firewall
# Source: https://www.digitalocean.com/community/tutorials/how-to-install-the-apache-web-server-on-ubuntu-16-04 (for more details, see https://www.digitalocean.com/community/tutorials/how-to-rewrite-urls-with-mod_rewrite-for-apache-on-ubuntu-16-04)
# Show apps that can be opened through the firewall
ufw app list
# Allow the default HTTP and HTTPS port, ports 80 and 443, through ufw:
ufw allow 'Apache Full'
# -OR-, only HTTPS via port 443
# ufw allow 'Apache Secure'
# Allow SSH through the firewall
ufw allow 'OpenSSH'
# Start the firewall
# CAUTION: Be -SURE- you at lease allowed 'OpenSSH' or you will be
# shut out of the server!!!
ufw enable
# View firewall configuration
ufw status verbose


# Configure domain name - DO THIS BEFORE GENERATING CERT!!! https://www.digitalocean.com/community/tutorials/how-to-set-up-a-host-name-with-digitalocean
# Change hostname while the OS is running:  http://ubuntuhandbook.org/index.php/2016/06/change-hostname-ubuntu-16-04-without-restart/
# Change /etc/hostname
vi /etc/hostname
# Change whatever is there to jackberrystudio

# Change /etc/hosts
vi /etc/hosts
# Change the line starting with 127.0.1.1 so that both names are jackberrystudio

# SSL Cert via Let's Encrypt
# See https://www.digitalocean.com/community/tutorials/how-to-use-certbot-standalone-mode-to-retrieve-let-s-encrypt-ssl-certificates
# and https://certbot.eff.org/all-instructions/#ubuntu-16-04-xenial-apache
# Follow instructions on digitalocean.com (first link); use the following
# for generating the cert in Step 2:
sudo certbot certonly --standalone --preferred-challenges tls-sni -d jackberrystudio.net -d jackberrystudio.com
# Use jackberrystudio@gmail.com when prompted for an email
# Agree to terms of service, but do not agree to sharing infor with EFF
# The following is printed out:
#   Obtaining a new certificate
#   Performing the following challenges:
#   tls-sni-01 challenge for jackberrystudio.net
#   tls-sni-01 challenge for jackberrystudio.com
#   Waiting for verification...
#   Cleaning up challenges
#   IMPORTANT NOTES:
#   - Congratulations! Your certificate and chain have been saved at:
#     /etc/letsencrypt/live/jackberrystudio.net/fullchain.pem
#     Your key file has been saved at:
#     /etc/letsencrypt/live/jackberrystudio.net/privkey.pem
#     Your cert will expire on 2017-12-07. To obtain a new or tweaked
#     version of this certificate in the future, simply run certbot
#     again. To non-interactively renew *all* of your certificates, run
#     "certbot renew"
#   - If you like Certbot, please consider supporting our work by:
#     Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
#     Donating to EFF:                    https://eff.org/donate-le

# To configure Apache 2.4 and SSL, see the following
# (see the Modify the Default Apache SSL Virtual Host File section) https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-apache-in-ubuntu-16-04
# Make a backup of the original config file
cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bk
# Modify default-ssl.conf with the changes below
vi /etc/apache2/sites-available/default-ssl.conf

# Right after <VirtualHost _default_:443>, add/modify:
ServerAdmin jackberrystudio@gmail.com
ServerName 165.227.17.32

# Modify SSLCertificateFile and SSLCertificateKeyFile with the absolute
# paths in the Let's Encrypt output, followed by a blank line and
# then the following:

# jsilber: wsgi config
WSGIDaemonProcess stemroi user=www-data group=www-data home=/var/www/stemroi python-path=/var/www/stemroi
WSGIScriptAlias /stemroi /var/www/stemroi/wsgi.py

<Directory "/var/www/stemroi">
    WSGIProcessGroup stemroi
    WSGIApplicationGroup stemroi
    WSGIScriptReloading On
    Order deny,allow
    deny from all
    <Files wsgi.py>
        Order deny,allow
        Allow from all
    </Files>
</Directory>

# Source: https://yoast.com/prevent-site-being-indexed/
# Before the closing </VirtualHost>, add the following:

# jsilber: Prevent search engine indexing
Header set X-Robots-Tag "noindex, nofollow"

# Save and quit the file--press Esc and then:
:wq!

# Enable our SSL config (SSL Virtual Host) with the a2ensite command:
a2ensite default-ssl

# Configure the default site with a rewrite rule to send all :80 traffic to
# :443 (SSL)
# Make a backup of the original config file
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf.bk
# Modify the enabled 000-default.conf with the changes below
vi /etc/apache2/sites-enabled/000-default.conf

# Before the closing </VirtualHost>, add the following:
# jsilber - redirect all :80 traffic to :443
RewriteEngine On
RewriteCond %{HTTPS} off
RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI}

# Save and quit the file--press Esc and then:
:wq!

# Test the config (last line should say 'Syntax OK'):
apache2ctl configtest

# To make https://jackberrystudio.com|.net redirect to https://jackberrystudio.com|.net/stemroi, do the following.
# Change the name of the default index.html page in Apache
mv /var/www/html/index.html /var/www/html/index.html_orig
# Replace Apache's default index.html with stemroi/conf/index.html
cp /var/www/stemroi/conf/index.html /var/www/html/.

# Start Apache or MySQL
systemctl start apache2|mysql
# To check the status of Apache or MySQL:
systemctl status apache2|mysql
# To stop Apache or MySQL:
systemctl stop apache2|mysql
# Restart Apache or MySQL
systemctl restart apache2|mysql

# Start here for research putting webapp URLs in their own directories...
# https://stackoverflow.com/questions/29882579/run-multiple-independent-flask-apps-in-ubuntu
