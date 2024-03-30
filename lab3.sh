!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-v]"
    echo "  -v: Enable verbose mode"
    exit 1
}

# Default settings
VERBOSE=false

# Parse command line options
while getopts ":v" opt; do
    case ${opt} in
        v)
            VERBOSE=true
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Transfer configure-host.sh script to server1-mgmt
scp configure-host.sh remoteadmin@server1-mgmt:/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to transfer configure-host.sh to server1-mgmt"
    exit 1
fi
sudo chmod +x configure-host.sh

# Run configure-host.sh script on server1-mgmt
ssh_command="ssh remoteadmin@server1-mgmt"
if [ "$VERBOSE" = true ]; then
    ssh_command+=" --verbose"
fi
$ssh_command -- /root/configure-host.sh -name loghost -ip 192.168.16.200 -hostentry webhost 192.168.16.201
if [ $? -ne 0 ]; then
    echo "Error: Failed to run configure-host.sh on server1-mgmt"
    exit 1
fi

# Transfer configure-host.sh script to server2-mgmt
scp configure-host.sh remoteadmin@server2-mgmt:/root
if [ $? -ne 0 ]; then
    echo "Error: Failed to transfer configure-host.sh to server2-mgmt"
    exit 1
fi

# Run configure-host.sh script on server2-mgmt
$ssh_command -- /root/configure-host.sh -name webhost -ip 192.168.16.201 -hostentry loghost 192.168.16.200
if [ $? -ne 0 ]; then
    echo "Error: Failed to run configure-host.sh on server2-mgmt"
    exit 1
fi

# Update local /etc/hosts file
./configure-host.sh -hostentry loghost 192.168.16.200
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local /etc/hosts file for loghost"
    exit 1
fi

./configure-host.sh -hostentry webhost 192.168.16.201
if [ $? -ne 0 ]; then
    echo "Error: Failed to update local /etc/hosts file for webhost"
    exit 1
fi

echo "Configuration applied successfully"
exit 0

