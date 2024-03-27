#!/bin/bash

# Function to check and configure network settings
function configure_network() {
    echo -e "\n### Configuring network settings ###"
    netplan_file="/etc/netplan/01-netcfg.yaml"
    if ! grep -q '192.168.16.21/24' "$netplan_file"; then
        echo "Updating netplan configuration..."
        cat <<EOF >> "$netplan_file"
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.16.21/24
        search:
          - home.arpa
          - localdomain
EOF
        netplan apply
        echo "Network configuration applied."
    else
        echo "Network configuration is already up to date."
    fi

    # Update /etc/hosts file
    hosts_file="/etc/hosts"
    if ! grep -q '192.168.16.21 server1' "$hosts_file"; then
        echo "Updating /etc/hosts file..."
        sed -i '/192.168.16.21/d' "$hosts_file"
        echo "192.168.16.21 server1" >> "$hosts_file"
        echo "/etc/hosts file updated."
    else
        echo "/etc/hosts file is already up to date."
    fi
}

# Function to check and install required software
function install_software() {
    echo -e "\n### Installing required software ###"
    if ! dpkg -l | grep -q 'apache2'; then
        echo "Installing apache2..."
        apt-get install -y apache2
        echo "Apache2 installed."
    else
        echo "Apache2 is already installed."
    fi

    if ! dpkg -l | grep -q 'squid'; then
        echo "Installing squid..."
        apt-get install -y squid
        echo "Squid installed."
    else
        echo "Squid is already installed."
    fi
}

# Function to configure firewall
function configure_firewall() {
    echo -e "\n### Configuring firewall ###"
    ufw status | grep -qw 'active' || ufw enable
    ufw allow from 192.168.16.0/24 to any port 22 proto tcp comment 'Allow SSH from mgmt network'
    ufw allow http comment 'Allow HTTP on both interfaces'
    ufw allow 3128 comment 'Allow web proxy on both interfaces'
    echo "Firewall configuration applied."
}

# Function to add a user
add_user() {
    local username=$1
    sudo useradd -m -s /bin/bash "$username"
    echo "User $username added successfully"
}

add_user "dennis"
add_user "aubrey"
add_user "captain"
add_user "snibbles"
add_user "brownie"
add_user "scooter"
add_user "sandy"
add_user "perrier"
add_user "cindy"
add_user "tiger"
add_user "yoda"
# Function to add user ssh keys
function add_ssh_keys() {
    local user=$1
    local ssh_dir="/home/$user/.ssh"
    local authorized_keys="$ssh_dir/authorized_keys"

    # Ensure .ssh directory exists
    if [ ! -d "$ssh_dir" ]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
        chown $user:$user "$ssh_dir"
    fi

    # Add ssh keys for rsa and ed25519 algorithms
    cat <<EOF > "$authorized_keys"
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm
EOF

    chmod 600 "$authorized_keys"
    chown $user:$user "$authorized_keys"
}

# Function to configure user accounts
function configure_users() {
    echo -e "\n### Configuring user accounts ###"
    local sudo_user="dennis"
    local users=("aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    for user in "${users[@]}"; do
        if id "$user" >/dev/null 2>&1; then
            echo "Configuring user $user..."
            usermod -s /bin/bash "$user"
            mkdir -p /home/"$user"/.ssh
            chown "$user":"$user" /home/"$user"/.ssh
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/$user/.ssh/authorized_keys"
            echo "RSA_PUBLIC_KEY" >> "/home/$user/.ssh/authorized_keys"  # Replace RSA_PUBLIC_KEY with the actual RSA public key
            echo "User $user configured."
        else
            echo "User $user does not exist."
        fi
    done
}


configure_network
install_software
configure_firewall
configure_users

echo -e "\n### Configuration completed ###"
