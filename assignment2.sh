#!/bin/bash

# Function to check if a package is installed
package_installed() {
    dpkg -l "$1" &> /dev/null
}

# Function to add a line to a file if it doesn't exist
add_line_to_file() {
    grep -qF "$1" "$2" || echo "$1" >> "$2"
}

# Function to ensure a directory exists
ensure_directory() {
    [ -d "$1" ] || mkdir -p "$1"
}

# Function to ensure a user exists with proper configurations
ensure_user() {
    local username=$1
    local ssh_key=$2
    
    if ! id "$username" &>/dev/null; then
        useradd -m -s /bin/bash "$username"
    fi
    
    ensure_directory "/home/$username/.ssh"
    add_line_to_file "$ssh_key" "/home/$username/.ssh/authorized_keys"
    chown -R "$username:$username" "/home/$username/.ssh"
    chmod 700 "/home/$username/.ssh"
    chmod 600 "/home/$username/.ssh/authorized_keys"
}

# Function to configure network interface using netplan
configure_netplan() {
    local config_file="/etc/netplan/01-netcfg.yaml"
    local new_config="
        network:
            version: 2
            renderer: networkd
            ethernets:
                ens192:
                    addresses: [192.168.16.21/24]
                    gateway4: 192.168.16.2
                    nameservers:
                        addresses: [192.168.16.2]
                        search: [home.arpa, localdomain]
    "
    echo "$new_config" > "$config_file"
    netplan apply
}

# Function to configure firewall using ufw
configure_firewall() {
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh from 192.168.16.0/24 to any
    ufw allow http
    ufw allow 3128
    ufw --force enable
}

# Function to install necessary packages
install_packages() {
    local packages=("apache2" "squid" "ufw")

    for pkg in "${packages[@]}"; do
        if ! package_installed "$pkg"; then
            apt-get -y install "$pkg"
        fi
    done
}

# Main function
main() {
    echo "=== Starting configuration ==="

    # Configure network interface
    echo "--- Configuring network interface ---"
    configure_netplan
    echo "Network interface configured successfully"

    # Configure /etc/hosts
    echo "--- Configuring /etc/hosts ---"
    sed -i '/192.168.16.21/s/.*/192.168.16.21 server1/' /etc/hosts
    echo "/etc/hosts configured successfully"

    # Install necessary packages
    echo "--- Installing necessary packages ---"
    install_packages
    echo "Packages installed successfully"

    # Configure firewall
    echo "--- Configuring firewall ---"
    configure_firewall
    echo "Firewall configured successfully"

    # Ensure user accounts and SSH keys
    echo "--- Ensuring user accounts and SSH keys ---"
    ensure_user "dennis" "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm"
    ensure_user "aubrey"
    ensure_user "captain"
    ensure_user "snibbles"
    ensure_user "brownie"
    ensure_user "scooter"
    ensure_user "sandy"
    ensure_user "perrier"
    ensure_user "cindy"
    ensure_user "tiger"
    ensure_user "yoda"
    echo "User accounts and SSH keys ensured successfully"

    echo "=== Configuration completed ==="
}

# Execute main function
main
