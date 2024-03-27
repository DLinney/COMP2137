#!/bin/bash

# Function to handle signals
handle_signal() {
    # Ignore TERM, HUP, and INT signals
    trap '' TERM HUP INT
}

# Set signal trap
trap handle_signal TERM HUP INT

# Function to log changes
log_change() {
    logger "configure-host.sh: $1"
}

# Function to update hostname
update_hostname() {
    local new_hostname="$1"
    local old_hostname=$(hostname)

    if [ "$new_hostname" != "$old_hostname" ]; then
        echo "$new_hostname" > /etc/hostname
        hostname "$new_hostname"
        sed -i "s/^127.0.1.1\s*$old_hostname/127.0.1.1 $new_hostname/g" /etc/hosts
        log_change "Changed hostname from $old_hostname to $new_hostname"
        if [ "$verbose" = true ]; then
            echo "Changed hostname from $old_hostname to $new_hostname"
        fi
    elif [ "$verbose" = true ]; then
        echo "Hostname is already set to $new_hostname"
    fi
}

# Function to update IP address
update_ip_address() {
    local new_ip="$1"
    local interface=$(ip route show default | awk '/default/ {print $5}')
    local old_ip=$(ip addr show "$interface" | awk '/inet / {print $2}' | cut -d'/' -f1)

    if [ "$new_ip" != "$old_ip" ]; then
        # Update netplan configuration
        netplan set "$interface".addresses="[$new_ip/24]"
        netplan apply

        # Update /etc/hosts
        sed -i "s/^$old_ip\s*$(hostname)/127.0.1.1 $(hostname)/g" /etc/hosts
        sed -i "/$old_ip/d" /etc/hosts
        echo "$new_ip $(hostname)" >> /etc/hosts

        log_change "Changed IP address for $interface from $old_ip to $new_ip"
        if [ "$verbose" = true ]; then
            echo "Changed IP address for $interface from $old_ip to $new_ip"
        fi
    elif [ "$verbose" = true ]; then
        echo "IP address is already set to $new_ip"
    fi
}

# Function to update /etc/hosts
update_hosts_entry() {
    local hostname="$1"
    local ip_address="$2"
    local entry="$ip_address $hostname"

    if ! grep -q "$entry" /etc/hosts; then
        echo "$entry" >> /etc/hosts
        log_change "Added $entry to /etc/hosts"
        if [ "$verbose" = true ]; then
            echo "Added $entry to /etc/hosts"
        fi
    elif [ "$verbose" = true ]; then
        echo "Entry $entry already exists in /etc/hosts"
    fi
}

# Parse command-line arguments
verbose=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        -verbose)
            verbose=true
            ;;
        -name)
            update_hostname "$2"
            shift
            ;;
        -ip)
            update_ip_address "$2"
            shift
            ;;
        -hostentry)
            update_hosts_entry "$2" "$3"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done
