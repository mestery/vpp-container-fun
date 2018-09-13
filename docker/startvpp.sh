#!/bin/bash

set -xe

ip link add name vpp1out type veth peer name vpp1host
ip link set dev vpp1out up
ip link set dev vpp1host up
ip addr add 10.10.1.1/24 dev vpp1host
ip route add 10.10.2.0/24 via 10.10.1.2
ip a
cat /etc/vpp/config1.txt
cat /etc/vpp/config2.txt

# Run the VPP daemons
/usr/bin/vpp -c /etc/vpp/startup1.conf
/usr/bin/vpp -c /etc/vpp/startup2.conf
