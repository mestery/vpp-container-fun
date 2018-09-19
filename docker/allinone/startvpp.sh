#!/bin/bash

set -xe

# Generate the config files
cat > /etc/vpp/config1.txt << EOL
create interface memif id 0 master
set in state memif0/0 up
set int ip address memif0/0 ${VPP1MEMIFIP}/${VPP1MEMIFMASK}
create host-interface name vpp1out
set int state host-vpp1out up
set int ip address host-vpp1out ${VPP1HOSTIP}/${VPP1HOSTMASK}
EOL

cat > /etc/vpp/config2.txt << EOL
create interface memif id 0 slave
set in state memif0/0 up
set int ip address memif0/0 ${VPP2MEMIFIP}/${VPP2MEMIFMASK}
ip route add ${VPP1HOSTROUTE}/${VPP1HOSTMASK} via ${VPP1MEMIFIP}
EOL

# Run the VPP daemons
/usr/bin/vpp -c /etc/vpp/startup1.conf
/usr/bin/vpp -c /etc/vpp/startup2.conf

# Setup the host link
ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add "${HOSTIP}"/"${HOSTMASK}" dev vpp1host
ip route add "${VPP2MEMIFROUTE}"/"${VPP2MEMIFMASK}" via "${VPP1HOSTIP}"

# Make sure VPP is *really* running
typeset -i cnt=60
until ls -l /run/vpp/cli-vpp1.sock ; do
       ((cnt=cnt-1)) || return 1
       sleep 1
done
typeset -i cnt=60
until ls -l /run/vpp/cli-vpp2.sock ; do
       ((cnt=cnt-1)) || return 1
       sleep 1
done

sudo vppctl -s /run/vpp/cli-vpp1.sock create host-interface name vpp1out
typeset -i cnt=60
until sudo vppctl -s /run/vpp/cli-vpp1.sock show int | grep vpp1out ; do
       ((cnt=cnt-1)) || return 1
       sleep 1
       sudo vppctl -s /run/vpp/cli-vpp1.sock create host-interface name vpp1out
done

sudo vppctl -s /run/vpp/cli-vpp1.sock set int state host-vpp1out up
sudo vppctl -s /run/vpp/cli-vpp1.sock set int ip address host-vpp1out "${VPP1HOSTIP}"/"${VPP1HOSTMASK}"

# We do not want to exit, so ...
tail -f /dev/null
