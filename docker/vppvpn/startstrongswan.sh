#!/bin/bash

set -xe

rm -f /usr/local/etc/strongswan.d/charon/kernel-netlink.conf
rm -f /usr/local/etc/strongswan.d/charon/socket-default.conf
cat >/usr/local/etc/strongswan.d/charon/kernel-vpp.conf << EOL
kernel-vpp {

    # Whether to load the plugin. Can also be an integer to increase the
    # priority of this plugin.
    load = yes

}
EOL

cat >/usr/local/etc/strongswan.d/charon/socket-vpp.conf << EOL
socket-vpp {

    # Whether to load the plugin. Can also be an integer to increase the
    # priority of this plugin.
    load = yes

    path = /run/vpp/read-punt.socket

}
EOL

mv /usr/local/etc/strongswan.d/charon-logging.conf /usr/local/etc/strongswan.d/charon-logging.conf.old
cat > /usr/local/etc/strongswan.d/charon-logging.conf << EOL
charon {

    # Section to define file loggers, see LOGGER CONFIGURATION in
    # strongswan.conf(5).
    filelog {

        /var/log {
            default = 5
        }
    }
}
EOL

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
        left=${VPPTUNNELIP}
        leftsubnet=${VPPSUBNET}/${VPPSUBNETMASK}
        leftauth=psk
        right=%any
        rightauth=psk
        auto=add
EOL
sudo mv /tmp/ipsec.conf /usr/local/etc/ipsec.conf

cat >/tmp/ipsec.secrets << EOL
: PSK "Vpp123"
EOL
sudo mv /tmp/ipsec.secrets /usr/local/etc/ipsec.secrets

ipsec start --debug-all
