#!/bin/bash

set -xe

cat >/tmp/ipsec.conf << EOL
config setup
        strictcrlpolicy=no

conn %default
        #ike=aes256-sha1-modp2048!
        #esp=aes192-sha1-esn!
        mobike=no
        keyexchange=ikev2
        ikelifetime=24h
        lifetime=24h

conn net-net
        right=${VPPTUNNELIP}
        rightsubnet=${VPPSUBNET}/${VPPSUBNETMASK}
        rightauth=psk
        left=${VPP_CLIENT_IP}
        #leftsubnet=${VPP_DOCKER_NETWORK_RANGE}
        leftauth=psk
        auto=add
EOL
sudo mv /tmp/ipsec.conf /usr/local/etc/ipsec.conf

cat >/tmp/ipsec.secrets << EOL
: PSK "Vpp123"
EOL
sudo mv /tmp/ipsec.secrets /usr/local/etc/ipsec.secrets

ip route add "${SWANSUBNET}"/"${SWANSUBNETMASK}" via "${VPP_SERVER_IP}"
ip route add "${VPP_GATEWAY_SUBNET}"/"${VPP_GATEWAY_SUBNET_MASK}" via "${VPP_SERVER_IP}"

ipsec start && sleep 5
ipsec up net-net

# We do not want to exit, so ...
tail -f /dev/null
