#!/bin/bash
#!/bin/bash

# Function to print messages for clarity
print_message() {
  echo "-----------------------------------------"
  echo "$1"
  echo "-----------------------------------------"
}

# Ensure the script is being run with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please try again with 'sudo'."
  exit 1
fi

# 1. Configure network interface for 192.168.16.21/24
print_message "Configuring network interface..."

netplan_file="/etc/netplan/00-installer-config.yaml"

# Check if the netplan file exists
if [ ! -f "$netplan_file" ]; then
  print_message "Netplan file $netplan_file not found! Please check the file path."
  exit 1
fi

# Check if the IP address 192.168.16.21 is already configured in the netplan file
if ! grep -q "192.168.16.21/24" "$netplan_file"; then
  print_message "Adding static IP 192.168.16.21/24 to $netplan_file..."

  # Insert static IP configuration if not already present
  sudo sed -i '/ethernets:/a \ \ \ \ eth0:\n\ \ \ \ \ \ dhcp4: false\n\ \ \ \ \ \ addresses:\n\ \ \ \ \ \ \ \ - 192.168.16.21/24' "$netplan_file"

  # Apply the netplan configuration
  sudo netplan apply
  print_message "Network interface eth0 configured with static IP 192.168.16.21/24."
else
  print_message "Network interface already configured with 192.168.16.21/24."
fi

# 2. Installing Apache2 and Squid if not already installed
print_message "Installing Apache2 and Squid..."

# Update package lists
sudo apt update -y

# Install Apache2 and Squid if not already installed
if ! dpkg -l | grep -q apache2; then
  sudo apt install apache2 -y
fi

if ! dpkg -l | grep -q squid; then
  sudo apt install squid -y
fi

# Enable and start the Apache2 and Squid services
sudo systemctl enable apache2
sudo systemctl start apache2
sudo systemctl enable squid
sudo systemctl start squid

print_message "Apache2 and Squid have been installed and started."

# 3. Update /etc/hosts file for server1
print_message "Updating /etc/hosts file..."

# Check if the entry already exists
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
  # If the entry doesn't exist, append it to the /etc/hosts file
  echo "192.168.16.21 server1" | sudo tee -a /etc/hosts > /dev/null
  print_message "Added 192.168.16.21 server1 to /etc/hosts."
else
  print_message "Entry for server1 already exists in /etc/hosts."
fi

# 4. Create users and set up SSH keys
users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
for user in "${users[@]}"; do
  print_message "Configuring user: $user..."

  # Create the user with home directory and bash shell
  if ! id -u "$user" &>/dev/null; then
    sudo useradd -m -s /bin/bash "$user"
  else
    print_message "User $user already exists."
  fi

  # Create the .ssh directory for the user
  sudo mkdir -p /home/$user/.ssh

  # Add SSH key for the user (using the provided key for 'dennis' as an example)
  if [ "$user" == "dennis" ]; then
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" | sudo tee /home/$user/.ssh/authorized_keys
  fi

  # Set proper permissions for .ssh and authorized_keys
  sudo chown -R $user:$user /home/$user/.ssh
  sudo chmod 700 /home/$user/.ssh
  sudo chmod 600 /home/$user/.ssh/authorized_keys

  # Add 'dennis' user to sudo group
  if [ "$user" == "dennis" ]; then
    sudo usermod -aG sudo "$user"
    print_message "User $user added to sudo group."
  fi
done

print_message "User configuration completed."

# 5. Final verification: List all users and check SSH keys
print_message "Final verification of users and SSH keys..."
for user in "${users[@]}"; do
  if id -u "$user" &>/dev/null; then
    print_message "User $user exists."
    if [ -f /home/$user/.ssh/authorized_keys ]; then
      print_message "User $user has an authorized_keys file."
    else
      print_message "User $user is missing authorized_keys."
    fi
  else
    print_message "User $user does NOT exist!"
  fi
done

print_message "Script completed successfully!"
