#!/bin/bash

# Define some useful functions
function print_section {
    echo "=============================="
    echo "$1"
    echo "=============================="
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root!"
    exit 1
fi

# Function to ensure a user exists and is configured properly
function configure_user {
    local username=$1
    local pubkey_rsa=$2
    local pubkey_ed25519=$3
    local ssh_dir="/home/$username/.ssh"
    
    # Ensure the user exists
    if ! id "$username" &>/dev/null; then
        echo "Creating user: $username"
        useradd -m -s /bin/bash "$username"
    else
        echo "User $username already exists."
    fi
    
    # Ensure SSH directory exists
    mkdir -p "$ssh_dir"
    chown "$username:$username" "$ssh_dir"
    
    # Create authorized_keys file if it doesn't exist
    touch "$ssh_dir/authorized_keys"
    chown "$username:$username" "$ssh_dir/authorized_keys"
    
    # Add provided public keys to authorized_keys
    echo "$pubkey_rsa" >> "$ssh_dir/authorized_keys"
    echo "$pubkey_ed25519" >> "$ssh_dir/authorized_keys"
    
    # Ensure the file permissions are correct
    chmod 600 "$ssh_dir/authorized_keys"
}

# Function to ensure Apache is installed and running
function configure_apache {
    if ! systemctl is-active --quiet apache2; then
        print_section "Installing Apache"
        apt update
        apt install -y apache2
        systemctl enable apache2
        systemctl start apache2
        echo "Apache installed and started."
    else
        echo "Apache is already installed and running."
    fi
}

# Function to ensure Squid is installed and running
function configure_squid {
    if ! systemctl is-active --quiet squid; then
        print_section "Installing Squid"
        apt update
        apt install -y squid
        systemctl enable squid
        systemctl start squid
        echo "Squid installed and started."
    else
        echo "Squid is already installed and running."
    fi
}

# Function to ensure network configurations are correct
function configure_network {
    print_section "Configuring Network"
    
    # Set the desired network configuration via netplan
    netplan_config="/etc/netplan/00-installer-config.yaml"
    
    # Backup the netplan configuration before modifying
    cp "$netplan_config" "$netplan_config.bak"
    
    # Ensure the network address is configured as required
    if ! grep -q "192.168.16.21/24" "$netplan_config"; then
        echo "Updating netplan configuration for 192.168.16.21/24"
        sed -i 's/addresses:.*$/addresses: [192.168.16.21\/24]/' "$netplan_config"
        netplan apply
    else
        echo "Network is already configured with 192.168.16.21/24"
    fi
}

# Function to ensure the /etc/hosts file is correct
function configure_hosts {
    print_section "Configuring /etc/hosts"
    
    # Ensure that the /etc/hosts file has the correct entry for server1
    if ! grep -q "192.168.16.21 server1" /etc/hosts; then
        echo "Updating /etc/hosts to include server1"
        echo "192.168.16.21 server1" >> /etc/hosts
    else
        echo "/etc/hosts already contains the correct entry for server1."
    fi
}

# Start script execution
print_section "Starting Assignment 2 Setup"

# Step 1: Configure the network
configure_network

# Step 2: Configure /etc/hosts
configure_hosts

# Step 3: Install and start Apache
configure_apache

# Step 4: Install and start Squid
configure_squid

# Step 5: Configure the users and their SSH keys
print_section "Configuring User Accounts"

# Public keys for the users
dennis_rsa="ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAtwt0fxVVn1Z2lT2a5IgpdzBd47GjRzbbA0fWz0tJQGjFT27pZg4pIjjlhJ25gHln2VGkBnlHhAT2RIXBhzwfV7bO5BHe7zqlwCINh+X7RzA7OOWfS0BdCkzQPx4Ro3g=="
dennis_ed25519="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

# Loop to configure all users
for user in "dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda"; do
    echo "Configuring user: $user"
    if [ "$user" == "dennis" ]; then
        configure_user "$user" "$dennis_rsa" "$dennis_ed25519"
        usermod -aG sudo "$user"  # Grant sudo access to dennis
    else
        configure_user "$user" "$dennis_rsa" "$dennis_ed25519"
    fi
done

print_section "User Accounts Configured"

echo "Assignment 2 Setup Complete!"

