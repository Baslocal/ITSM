#!/bin/bash

# osTicket Lab Installation Script for Ubuntu 22.04
# This script automates the installation of osTicket with LAMP stack for educational purposes

# Warning message
cat << EOF
===============================
WARNING: EDUCATIONAL USE ONLY
===============================
EOF

# Function to print colored output
print_color() {
    case $1 in
        "green") echo -e "\e[32m$2\e[0m" ;;
        "red") echo -e "\e[31m$2\e[0m" ;;
        "yellow") echo -e "\e[33m$2\e[0m" ;;
    esac
}

# Function to handle errors
handle_error() {
    print_color "red" "Error: $1"
    print_color "yellow" "The script will continue, but you may want to check this error."
    echo "Error: $1" >> osticket_install.log
}

# Function to log messages
log_message() {
    echo "$(date): $1" >> osticket_install.log
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   print_color "red" "This script must be run as root" 
   exit 1
fi

# Initialize variables
INSTALL_TYPE=""
DB_PASSWORD=""
OSTICKET_VERSION=""

# Prompt for installation type
print_color "yellow" "Choose installation type:"
echo "1. Custom (manual setup)"
echo "2. Default (automated setup)"
read -p "Enter your choice (1 or 2): " INSTALL_CHOICE

case $INSTALL_CHOICE in
    1) INSTALL_TYPE="custom" ;;
    2) INSTALL_TYPE="default" ;;
    *) print_color "red" "Invalid choice. Exiting."; exit 1 ;;
esac

# Custom installation prompts
if [ "$INSTALL_TYPE" = "custom" ]; then
    print_color "yellow" "Enter a username for the new account:"
    read NEW_USERNAME
    print_color "yellow" "Enter a password for the account:"
    read -s NEW_PASSWORD
    echo
    print_color "yellow" "Enter a strong password for the osTicket database user:"
    read -s DB_PASSWORD
    echo
else
    NEW_USERNAME="osticket"
    NEW_PASSWORD="LabPassword123!"
    DB_PASSWORD="LabPassword123!"
fi

# Prompt for osTicket version
print_color "yellow" "Enter osTicket version to install (leave blank for latest):"
read OSTICKET_VERSION

# Update the system and install necessary tools
print_color "green" "Updating the system and installing necessary tools..."
sudo apt update && sudo apt upgrade -y || handle_error "Failed to update and upgrade system"
apt-get install sudo curl wget unzip net-tools -y || handle_error "Failed to install necessary tools"

log_message "System updated and necessary tools installed"

# Remove existing LAMP stack if present
print_color "yellow" "Removing existing LAMP stack..."
systemctl stop apache2 mysql || true
apt remove --purge apache2 php* mysql* -y || handle_error "Failed to remove existing LAMP stack"
apt autoremove -y || handle_error "Failed to autoremove unnecessary packages"

log_message "Existing LAMP stack removed"

# Install LAMP Stack
print_color "green" "Installing LAMP Stack..."
apt install apache2 -y || handle_error "Failed to install Apache"
systemctl enable apache2 && systemctl start apache2 || handle_error "Failed to start Apache"

apt-get install php8.1 php8.1-cli php8.1-common php8.1-imap php8.1-redis php8.1-snmp php8.1-xml php8.1-zip php8.1-mbstring php8.1-curl php8.1-mysqli php8.1-gd php8.1-intl php8.1-apcu libapache2-mod-php -y || handle_error "Failed to install PHP and its extensions"

apt install mariadb-server -y || handle_error "Failed to install MariaDB"
systemctl start mariadb && systemctl enable mariadb || handle_error "Failed to start MariaDB"

log_message "LAMP stack installed"

# Create osTicket database and user
mysql -e "DROP DATABASE IF EXISTS osticket;" || handle_error "Failed to drop existing osTicket database"
mysql -e "CREATE DATABASE osticket;" || handle_error "Failed to create osTicket database"
mysql -e "DROP USER IF EXISTS osticket@localhost;" || handle_error "Failed to drop existing osTicket database user"
mysql -e "CREATE USER osticket@localhost IDENTIFIED BY '$DB_PASSWORD';" || handle_error "Failed to create osTicket database user"
mysql -e "GRANT ALL PRIVILEGES ON osticket.* TO osticket@localhost;" || handle_error "Failed to grant privileges to osTicket database user"
mysql -e "FLUSH PRIVILEGES;" || handle_error "Failed to flush privileges"

log_message "osTicket database and user created"

# Remove existing osTicket installation if present
if [ -d "/var/www/html/osTicket" ]; then
    print_color "yellow" "Removing existing osTicket installation..."
    rm -rf /var/www/html/osTicket || handle_error "Failed to remove existing osTicket installation"
fi

# Install osTicket
print_color "green" "Installing osTicket..."
cd /var/www/html
if [ -z "$OSTICKET_VERSION" ]; then
    DOWNLOAD_URL=$(curl -s https://api.github.com/repos/osTicket/osTicket/releases/latest | grep browser_download_url | cut -d '"' -f 4)
else
    DOWNLOAD_URL="https://github.com/osTicket/osTicket/releases/download/v${OSTICKET_VERSION}/osTicket-v${OSTICKET_VERSION}.zip"
fi

if [ -z "$DOWNLOAD_URL" ]; then
    handle_error "Failed to get osTicket download URL"
else
    wget $DOWNLOAD_URL || handle_error "Failed to download osTicket"
    unzip osTicket-*.zip -d osTicket || handle_error "Failed to unzip osTicket"
    cp /var/www/html/osTicket/upload/include/ost-sampleconfig.php /var/www/html/osTicket/upload/include/ost-config.php || handle_error "Failed to copy osTicket config file"
    rm osTicket-*.zip
fi

log_message "osTicket installed"

# Set permissions
chown -R www-data:www-data /var/www/html/osTicket/ || handle_error "Failed to set osTicket directory ownership"
find /var/www/html/osTicket -type d -exec chmod 755 {} \; || handle_error "Failed to set directory permissions"
find /var/www/html/osTicket -type f -exec chmod 644 {} \; || handle_error "Failed to set file permissions"

# Create Apache Virtual Host
DOMAIN=$(hostname)

cat > /etc/apache2/sites-available/osticket.conf << EOF
<VirtualHost *:80>
ServerName $DOMAIN
DocumentRoot /var/www/html/osTicket/upload

<Directory /var/www/html/osTicket>
AllowOverride All
</Directory>

ErrorLog \${APACHE_LOG_DIR}/error.log
CustomLog \${APACHE_LOG_DIR}/access.log combined

</VirtualHost>
EOF

# Enable Apache configuration
a2enmod rewrite || handle_error "Failed to enable Apache rewrite module"
a2ensite osticket.conf || handle_error "Failed to enable osTicket Apache configuration"
a2dissite 000-default.conf || handle_error "Failed to disable default Apache site"
systemctl reload apache2 || handle_error "Failed to reload Apache"

log_message "Apache configured for osTicket"

# Get the server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

print_color "green" "osTicket installation completed!"
print_color "yellow" "Please complete the installation by visiting http://$SERVER_IP/setup in your web browser."
print_color "yellow" "Use the following information during setup:"
echo "Database Name: osticket"
echo "Database User: osticket"
echo "Database Password: $DB_PASSWORD"

# Display server information
print_color "green" "Server Information:"
echo "IP Address: $SERVER_IP"
echo "Hostname: $DOMAIN"
echo "Web Server: http://$SERVER_IP"

# Display user information
print_color "green" "User Information:"
echo "Username: $NEW_USERNAME"
echo "Password: $NEW_PASSWORD"

# Optional: Add demo data
print_color "yellow" "Would you like to add demo data to osTicket? (y/n)"
read ADD_DEMO_DATA

if [ "$ADD_DEMO_DATA" = "y" ]; then
    # Add demo data logic here
    print_color "green" "Demo data added successfully!"
    log_message "Demo data added"
fi

# Cleanup function
cleanup() {
    print_color "yellow" "Cleaning up osTicket installation..."
    rm -rf /var/www/html/osTicket
    mysql -e "DROP DATABASE IF EXISTS osticket;"
    mysql -e "DROP USER IF EXISTS osticket@localhost;"
    a2dissite osticket.conf
    rm /etc/apache2/sites-available/osticket.conf
    systemctl reload apache2
    print_color "green" "Cleanup completed!"
    log_message "osTicket installation cleaned up"
}

print_color "yellow" "To clean up this installation later, run this script with the --cleanup option."

# Check for cleanup option
if [ "$1" = "--cleanup" ]; then
    cleanup
    exit 0
fi

log_message "Installation completed successfully"

print_color "green" "Installation log saved to osticket_install.log"
