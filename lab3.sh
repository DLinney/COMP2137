#!/bin/bash

# Check if -verbose option is provided
if [ "$1" = "-verbose" ]; then
    verbose=true
    shift
else
    verbose=false
fi

# Copy configure-host.sh to remote servers
scp configure-host.sh remoteadmin@server1-mgmt:/root
scp configure-host.sh remoteadmin@server2-mgmt:/root

# Run configure-host.sh on remote servers
if [ "$verbose" = true ]; then
    ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -verbose -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
    ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -verbose -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3
else
    ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4
    ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3
fi

# Update local /etc/hosts
./configure-host.sh -hostentry loghost 192.168.16.3
./configure-host.sh -hostentry webhost 192.168.16.4
