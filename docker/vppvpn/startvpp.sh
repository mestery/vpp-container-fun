#!/bin/bash

set -xe

set -xe

# Create tun interface
mkdir -p /dev/net
if [ ! -e /dev/net/tun ] ; then
  mknod /dev/net/tun c 10 200
  chmod 666 /dev/net/tun
fi

# Run the VPP daemon
/usr/bin/vpp -c /etc/vpp/startup.conf

# Make sure VPP is *really* running
typeset -i cnt=60
until ls -l /run/vpp/cli-vpp1.sock ; do
       ((cnt=cnt-1)) || exit 1
       sleep 1
done

sudo vppctl -s /run/vpp/cli-vpp1.sock tap connect gateway address "${SWANTUNNELIP}"/"${VPPSUBNETMASK}"
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface state tapcli-0 up
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface ip address tapcli-0 "${VPPTUNNELIP}"/"${VPPSUBNETMASK}"
sudo vppctl -s /run/vpp/cli-vpp1.sock tap connect gw-net
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface state tapcli-1 up
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface ip address tapcli-1 "${VPPOUTERIP}"/"${VPPSUBNETMASK}"

# Move gw-net interface to it's own namespace
ip netns add "${OUTERNAMESPACE}"
ip link set gw-net netns "${OUTERNAMESPACE}"
ip netns exec "${OUTERNAMESPACE}" ip link set lo up
ip netns exec "${OUTERNAMESPACE}" ip link set gw-net up
ip netns exec "${OUTERNAMESPACE}" ip addr add "${HOSTOUTERIP}"/"${OUTERMASK}" dev gw-net
ip netns exec "${OUTERNAMESPACE}" ip route add default via "${VPPOUTERIP}"

sudo vppctl -s /run/vpp/cli-vpp1.sock ip route add "${VPP_DOCKER_SUBNET}"/"${VPP_DOCKER_SUBNET_MASK}" via "${SWANTUNNELIP}" tapcli-0
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface ipsec spd tapcli-0 1
SILLYMAC=$(ip link| grep -A 1 gateway|grep ether | cut -d " " -f 6)
sudo vppctl -s /run/vpp/cli-vpp1.sock set ip arp tapcli-0 "${VPP_CLIENT_IP}" "${SILLYMAC}"

# Start strongswan
/startstrongswan.sh

# We do not want to exit, so ...
tail -f /dev/null
