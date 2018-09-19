#!/bin/bash

set -xe

# Generate the config file
cat > /etc/vpp/config1.txt << EOL
create interface memif id 0 master
set in state memif0/0 up
set int ip address memif0/0 ${VPP1MEMIFIP}/${VPP1MEMIFMASK}
EOL

# Run the VPP daemon
/usr/bin/vpp -c /etc/vpp/startup1.conf

# Setup the host link
ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add "${HOSTIP}"/"${HOSTMASK}" dev vpp1host
ip route add "${MEMIFROUTE}"/"${MEMIFMASK}" via "${VPP1HOSTINTIP}"

# Make sure VPP is *really* running
typeset -i cnt=60
until ls -l /run/vpp/cli-vpp1.sock ; do
       ((cnt=cnt-1)) || exit 1
       sleep 1
done

sudo vppctl -s /run/vpp/cli-vpp1.sock create host-interface name vpp1out
typeset -i cnt=60
until sudo vppctl -s /run/vpp/cli-vpp1.sock show int | grep vpp1out ; do
       ((cnt=cnt-1)) || exit 1
       sleep 1
       sudo vppctl -s /run/vpp/cli-vpp1.sock create host-interface name vpp1out
done

sudo vppctl -s /run/vpp/cli-vpp1.sock set int state host-vpp1out up
sudo vppctl -s /run/vpp/cli-vpp1.sock set int ip address host-vpp1out "${VPP1HOSTINTIP}"/"${VPP1HOSTINTMASK}"

# We do not want to exit, so ...
tail -f /dev/null
