!/bin/bash

# Function to log changes
log_changes() {
    if [ "$VERBOSE" = true ]; then
        echo "$1"
    else
        logger -t configure-host "$1"
    fi
}

# Function to handle signals
trap '' TERM HUP INT

# Default settings
VERBOSE=false
DESIRED_NAME="Assignment3"
DESIRED_IP="192.168.16.4"
DESIRED_NAME_HOSTENTRY="Assignment3"
DESIRED_IP_HOSTENTRY="192.168.92.1"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Configure host name
CURRENT_NAME=$(hostname)
if [ "$DESIRED_NAME" != "$CURRENT_NAME" ]; then
    sudo sed -i "s/$CURRENT_NAME/$DESIRED_NAME/g" /etc/hosts /etc/hostname
    log_changes "Hostname changed to $DESIRED_NAME"
else
    log_changes "Hostname already set to $DESIRED_NAME"
fi

# Configure IP address
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [ "$DESIRED_IP" != "$CURRENT_IP" ]; then
    sudo sed -i "s/$CURRENT_IP/$DESIRED_IP/g" /etc/hosts
    sudo sed -i "s/addresses: \[ $CURRENT_IP/addresses: \[ $DESIRED_IP/g" /etc/netplan/*.yaml
    sudo netplan apply
    log_changes "IP address changed to $DESIRED_IP"
else
    log_changes "IP address already set to $DESIRED_IP"
fi

# Configure host entry
if grep -q "$DESIRED_NAME_HOSTENTRY" /etc/hosts && grep -q "$DESIRED_IP_HOSTENTRY" /etc/hosts; then
    log_changes "Host entry already exists for $DESIRED_NAME_HOSTENTRY with IP $DESIRED_IP_HOSTENTRY"
else
    echo "$DESIRED_IP_HOSTENTRY $DESIRED_NAME_HOSTENTRY" | sudo tee -a /etc/hosts > /dev/null
    log_changes "Added host entry for $DESIRED_NAME_HOSTENTRY with IP $DESIRED_IP_HOSTENTRY"
fi

exit 0

