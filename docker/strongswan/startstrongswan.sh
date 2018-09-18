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
        right=10.10.1.2
        rightsubnet=192.168.124.0/24
        rightauth=psk
        rightid=@vpp.home
        left=10.10.1.1
        leftsubnet=192.168.125.0/24
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
