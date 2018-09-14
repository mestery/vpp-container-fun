#!/bin/bash

set -xe

# Run the VPP daemons
/usr/bin/vpp -c /etc/vpp/startup1.conf
/usr/bin/vpp -c /etc/vpp/startup2.conf

# Setup the host link
ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add 10.10.1.1/24 dev vpp1host
ip route add 10.10.2.0/24 via 10.10.1.2

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
sudo vppctl -s /run/vpp/cli-vpp1.sock set int ip address host-vpp1out 10.10.1.2/24

# We do not want to exit, so ...
tail -f /dev/null
