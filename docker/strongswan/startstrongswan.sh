#!/bin/bash

set -xe

cat >/tmp/ipsec.conf << EOL
config setup
        strictcrlpolicy=no

conn %default
        ike=aes256-sha1-modp2048!
        esp=aes192-sha1-esn!
        mobike=no
        keyexchange=ikev2
        ikelifetime=24h
        lifetime=24h

conn net-net
        right=${VPPTUNNELIP}
        rightsubnet=${VPPSUBNET}/${VPPSUBNETMASK}
        rightauth=psk
        rightid=@vpp.home
        left=${SWANTUNNELIP}
        leftsubnet=${SWANSUBNET}/${SWANSUBNETMASK}
        leftauth=psk
        leftid=@roadwarrior.vpn.example.com
        auto=start
EOL
sudo mv /tmp/ipsec.conf /etc/strongswan/ipsec.conf

cat >/tmp/ipsec.secrets << EOL
: PSK "Vpp123"
EOL
sudo mv /tmp/ipsec.secrets /etc/strongswan/ipsec.secrets

/usr/sbin/strongswan start
