#!/bin/bash

set -xe

# Run the VPP daemon
/usr/bin/vpp -c /etc/vpp/startup.conf

# Setup the host link
ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add "${SWANTUNNELIP}"/"${SWANSUBNETMASK}" dev vpp1host

# Create host loopback IP
ip link add name swan1 type dummy
ip link set dev swan1 up
ip address add "${SWANOUTERIP}"/"${SWANSUBNETMASK}" dev swan1
ip route add "${VPPSUBNET}"/"${VPPSUBNETMASK}" via "${VPPTUNNELIP}"
ip route add "${VPPIPSECROUTE}"/"${VPPIPSECMASK}" via "${VPPTUNNELIP}"

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
sudo vppctl -s /run/vpp/cli-vpp1.sock set int ip address host-vpp1out "${VPPTUNNELIP}"/"${VPPSUBNETMASK}"

# VPP IKEv2 Configuration
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile add pr1
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile set pr1 auth shared-key-mic string Vpp123
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile set pr1 id local fqdn vpp.home
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile set pr1 id remote fqdn roadwarrior.vpn.example.com
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile set pr1 traffic-selector local ip-range 192.168.124.0 - 192.168.124.255 port-range 0 - 65535 protocol 0
sudo vppctl -s /run/vpp/cli-vpp1.sock ikev2 profile set pr1 traffic-selector remote ip-range 192.168.125.0 - 192.168.125.255 port-range 0 - 65535 protocol 0

# Start strongswan
/startstrongswan.sh

# Wait for the tunnel to come up
typeset -i cnt=60
until sudo vppctl -s /run/vpp/cli-vpp1.sock show int | grep ipsec0 ; do
       ((cnt=cnt-1)) || exit 1
       sleep 1
done

# Create VPP loopback
sudo vppctl -s /run/vpp/cli-vpp1.sock loopback create-interface
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface state loop0 up
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface ip address loop0 "${VPPOUTERIP}"/"${VPPSUBNETMASK}"
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface state ipsec0 up
sudo vppctl -s /run/vpp/cli-vpp1.sock set interface ip address ipsec0 "${VPPIPSECROUTE}"/"${VPPIPSECMASK}"
sudo vppctl -s /run/vpp/cli-vpp1.sock ip route add "${SWANSUBNET}"/"${SWANSUBNETMASK}" via "${VPPIPSECIP}" ipsec0

# We do not want to exit, so ...
tail -f /dev/null
