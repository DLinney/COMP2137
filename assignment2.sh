#!/bin/bash

# Variables
netplan_file="/etc/netplan/01-netcfg.yaml"
hosts_file="/etc/hosts"

# Functions
function check_software() {
    echo -e "\nChecking software installation..."
    if ! dpkg -l | grep -q 'apache2'; then
        echo "Installing apache2..."
        apt-get install -y apache2
    fi
    if ! dpkg -l | grep -q 'squid'; then
        echo "Installing squid..."
        apt-get install -y squid
    fi
    if ! dpkg -l | grep -q 'ufw'; then
        echo "Installing ufw..."
        apt-get install -y ufw
    fi
}

function check_netplan() {
    echo -e "\nChecking netplan configuration..."
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
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search:
          - home.arpa
          - localdomain
EOF
        netplan apply
    fi
}

function check_hosts() {
    echo -e "\nChecking /etc/hosts file..."
    if ! grep -q '192.168.16.21 server1' "$hosts_file"; then
        echo "Updating /etc/hosts file..."
        echo "192.168.16.21 server1" >> "$hosts_file"
    fi
    if grep -q '192.168.16.11 server1' "$hosts_file"; then
        echo "Removing old IP address from /etc/hosts file..."
        sed -i '/192.168.16.11/d' "$hosts_file"
    fi
}

function check_firewall() {
    echo -e "\nChecking firewall configuration..."
    if ! ufw status | grep -q '22/tcp ALLOW IN'; then
        echo "Allowing SSH on mgmt network..."
        ufw allow from 192.168.16.0/24 to any port 22 proto tcp
    fi
    if ! ufw status | grep -q '80/tcp ALLOW IN'; then
        echo "Allowing HTTP on both interfaces..."
        ufw allow http
    fi
    if ! ufw status | grep -q '3128/tcp ALLOW IN'; then
        echo "Allowing web proxy on both interfaces..."
        ufw allow 3128/tcp
    fi
    if ! ufw status | grep -qw 'enabled'; then
        echo "Enabling firewall..."
        ufw enable
    fi
}

function check_users() {
    echo -e "\nChecking user accounts..."
    for user in dennis aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda; do
        if id -u "$user" >/dev/null 2>&1; then
            echo "Updating user account for $user..."
            usermod -d /home/"$user" "$user"
            usermod -s /bin/bash "$user"
            if [ "$user" == "dennis" ]; then
                echo "Adding sudo access for $user..."
                usermod -aG sudo "$user"
            fi
            mkdir -p /home/"$user"/.ssh
            chown "$user":"$user" /home/"$user"/.ssh
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/$user/.ssh/authorized_keys"
            echo "Adding user's public key to authorized_keys file..."
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL11t9vJjb82KzKO5zUJi8q5jvR2pCjszHZ5/DWsL1Qy7qYzJ6R0jmJoaZfrl3T2jBJrSz1nQy+HrQwXfNfKwVxHvh7RVi98bJzGK2lEsmvQJwUHvM6HKEqTcBk5v/1iXa15jCLY4g09fRyfYl1jf0xQ9gR3a4z6VZwJ85jP2r/KHhxG2xYH2NxFuhoXvTjJHMxTvNnqm+s7lLH05QBv0/74jx2nUJzY1Xq2vZG6w9hZbWq/gJjWxPm3G1WkXUqP5+QdR5Y2qCjzN+XrPfQ2jE6WVnD8OHwWgZm0gQ3FzpE9 +user-rsa-key >> /home/$user/.ssh/authorized_keys"
        else
            echo "Creating new user account for $user..."
            adduser --home /home/"$user" --shell /bin/bash "$user"
            if [ "$user" == "dennis" ]; then
                echo "Adding sudo access for $user..."
                adduser "$user" sudo
            fi
            mkdir -p /home/"$user"/.ssh
            chown "$user":"$user" /home/"$user"/.ssh
            echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> "/home/$user/.ssh/authorized_keys"
            echo "Adding user's public key to authorized_keys file..."
            echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL11t9vJjb82KzKO5zUJi8q5jvR2pCjszHZ5/DWsL1Qy7qYzJ6R0jmJoaZfrl3T2jBJrSz1nQy+HrQwXfNfKwVxHvh7RVi98bJzGK2lEsmvQJwUHvM6HKEqTcBk5v/1iXa15jCLY4g09fRyfYl1jf0xQ9gR3a4z6VZwJ85jP2r/KHhxG2xYH2NxFuhoXvTjJHMxTvNnqm+s7lLH05QBv0/74jx2nUJzY1Xq2vZG6w9hZbWq/gJjWxPm3G1WkXUqP5+QdR5Y2qCjzN+XrPfQ2jE6WVnD8OHwWgZm0gQ3FzpE9 +user-rsa-key >> /home/$user/.ssh/authorized_keys"
        fi
    done
}

# Main
echo -e "
#  Server 1 Configuration Script #
"

check_software
check_netplan
check_hosts
check_firewall
check_users

echo-e "\n

$(netplan apply && ip addr show eth0)
$(cat /etc/hosts)
$(ufw status)
$(cat /etc/sudoers.d/dennis)
$(cat /home/dennis/.ssh/authorized_keys)
$(cat /etc/netplan/*.yaml)
"
