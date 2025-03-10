#!/bin/bash

# Start of the script
echo "Starting Assignment 2 script execution..."

# 1. Check and apply network configuration
echo "Checking and applying network configuration..."
CURRENT_IP=$(ip a | grep -oP 'inet \K[\d.]+')
DESIRED_IP="192.168.16.21"

# If current IP doesn't match desired IP
if [[ "$CURRENT_IP" != "$DESIRED_IP" ]]; then
    echo "Changing IP address to $DESIRED_IP"

    # Backup existing netplan configuration
    cp /etc/netplan/*.yaml /etc/netplan/*.yaml.bak
    
    # Replace current IP with the desired IP in the netplan config
    sed -i "s/$CURRENT_IP/$DESIRED_IP/" /etc/netplan/*.yaml

    # Apply the new netplan configuration
    netplan apply
else
    echo "Network configuration is correct."
fi

# 2. Modify /etc/hosts file
echo "Checking and modifying /etc/hosts..."

HOSTS_FILE="/etc/hosts"
EXPECTED_ENTRY="192.168.16.21 server1"

# Check if the entry is already in /etc/hosts
if ! grep -q "$EXPECTED_ENTRY" "$HOSTS_FILE"; then
    echo "$EXPECTED_ENTRY" >> "$HOSTS_FILE"
    echo "Added $EXPECTED_ENTRY to /etc/hosts."
else
    echo "Entry for server1 already exists in /etc/hosts."
fi

# 3. Install required software: apache2 and squid
echo "Checking and installing required software..."

# Check if apache2 is installed
if ! dpkg -l | grep -q apache2; then
    echo "Installing apache2..."
    apt-get update && apt-get install -y apache2
else
    echo "apache2 is already installed."
fi

# Check if squid is installed
if ! dpkg -l | grep -q squid; then
    echo "Installing squid..."
    apt-get update && apt-get install -y squid
else
    echo "squid is already installed."
fi

# 4. Create users and configure SSH keys
echo "Creating user accounts and configuring SSH keys..."

USER_LIST=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"

for USER in "${USER_LIST[@]}"; do
    # Check if user exists
    if id "$USER" &>/dev/null; then
        echo "User $USER already exists."
    else
        echo "Creating user $USER..."
        useradd -m -s /bin/bash "$USER"
        
        # Add 'dennis' to sudo group
        if [[ "$USER" == "dennis" ]]; then
            usermod -aG sudo "$USER"
        fi
    fi

    # Create the .ssh directory for the user and set correct permissions
    USER_SSH_DIR="/home/$USER/.ssh"
    mkdir -p "$USER_SSH_DIR"
    
    # Add the public SSH key
    echo "$SSH_KEY" > "$USER_SSH_DIR/authorized_keys"
    chown -R "$USER":"$USER" "$USER_SSH_DIR"
    chmod 700 "$USER_SSH_DIR"
    chmod 600 "$USER_SSH_DIR/authorized_keys"
    
    echo "SSH key setup for $USER."
done

echo "Script execution complete."
