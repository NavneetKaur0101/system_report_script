#!/bin/bash

# Store current date/time for the report header
REPORT_DATE=$(date)

# Gather system information
HOSTNAME=$(hostname)
OS_INFO=$(source /etc/os-release && echo "$NAME $VERSION")
UPTIME=$(uptime -p)

# Gather hardware information
CPU=$(lscpu | grep "Model name" | cut -d: -f2 | sed 's/^ //')
RAM=$(free -h | grep Mem | awk '{print $2}')
DISK=$(lsblk -o NAME,SIZE,MODEL | grep -v NAME | awk '{print $3 " " $2}')
VIDEO=$(lspci | grep -i vga | awk -F': ' '{print $2}')

# Gather network information
FQDN=$(hostname -f)
IP_ADDRESS=$(ip a | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip r | grep default | awk '{print $3}')
DNS_SERVER=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

# Gather system status
LOGGED_IN_USERS=$(who | awk '{print $1}' | sort | uniq | tr '\n' ', ' | sed 's/, $//')
DISK_SPACE=$(df -h --output=source,avail | grep -v 'Filesystem' | awk '{print $1 " " $2}' | tr '\n' ' ')
PROCESS_COUNT=$(ps aux --no-headers | wc -l)
LOAD_AVERAGES=$(uptime | awk -F'load average: ' '{print $2}' | sed 's/,/ /g')
LISTENING_PORTS=$(ss -tuln | grep LISTEN | wc -l)
UFW_STATUS=$(ufw status | grep -i status | awk '{print $2}')

# Print the system report
cat << EOF

System Report generated by $USER, $REPORT_DATE

System Information
------------------
Hostname: $HOSTNAME
OS: $OS_INFO
Uptime: $UPTIME

Hardware Information
--------------------
CPU: $CPU
RAM: $RAM
Disk(s): $DISK
Video: $VIDEO

Network Information
-------------------
FQDN: $FQDN
Host Address: $IP_ADDRESS
Gateway IP: $GATEWAY
DNS Server: $DNS_SERVER

System Status
-------------
Users Logged In: $LOGGED_IN_USERS
Disk Space: $DISK_SPACE
Process Count: $PROCESS_COUNT
Load Averages: $LOAD_AVERAGES
Listening Network Ports: $LISTENING_PORTS
UFW Status: $UFW_STATUS

EOF
