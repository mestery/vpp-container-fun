#!/bin/bash

set -xe

mv /etc/strongswan.d/charon-logging.conf /etc/strongswan.d/charon-logging.conf.old
cat > /etc/strongswan.d/charon-logging.conf << EOL
charon {
    # two defined file loggers
    filelog {
        charon {
            # path to the log file, specify this as section name in versions prior to 5.7.0
            path = /var/log/charon.log
            # add a timestamp prefix
            time_format = %b %e %T
            # prepend connection name, simplifies grepping
            ike_name = yes
            # overwrite existing files
            append = no
            # increase default loglevel for all daemon subsystems
            default = 1
            # flush each line to disk
            flush_line = yes
        }
        stderr {
            # more detailed loglevel for a specific subsystem, overriding the
            # default loglevel.
            ike = 2
            knl = 3
        }
    }
}
EOL

# Configure HA mode
cat > /etc/strongswan.d/charon/ha.conf << EOL
ha {
    load = yes

    # Interval in seconds to automatically balance handled segments between
    # nodes. Set to 0 to disable.
    # autobalance = 0

    fifo_interface = yes
    #heartbeat_delay = 1000
    #heartbeat_timeout = 2100
    #heartbeat_delay = 250
    #heartbeat_timeout = 1000

    # Whether to load the plugin. Can also be an integer to increase the
    # priority of this plugin.
    load = yes
    local = ${SERVER1_IP}
    monitor = yes
    # pools =
    remote = ${SERVER2_IP}
    resync = yes
    # secret =
    segment_count = 1

    pools {
      testpool = 10.223.220.0/22
    }
}
EOL

cat >/tmp/ipsec.conf << EOL
config setup
        strictcrlpolicy=no

conn %default
        esp=aes128gcm8
        mobike=no
        keyexchange=ikev2
        ikelifetime=24h
        lifetime=24h

conn net-net
        type=tunnel
        left=${CLUSTERIP}
        leftsubnet=${VPN_SUBNET}/${VPN_SUBNET_MASK}
        leftsourceip=%testpool
        leftauth=psk
        right=%any
        rightauth=psk
        auto=add
EOL
sudo mv /tmp/ipsec.conf /etc/ipsec.conf

cat >/tmp/ipsec.secrets << EOL
: PSK "Vpp123"
EOL
sudo mv /tmp/ipsec.secrets /etc/ipsec.secrets

# Setup keepalived
cat > /etc/keepalived/keepalived.conf << EOL
! Configuration File for keepalived

vrrp_sync_group VG1 {
  group {
    VI_1
    VI_2
  }
}
 
vrrp_instance VI_1 {
  state MASTER
  interface eth0
  virtual_router_id 51
  priority 150
  advert_int 1
  nopreempt
  authentication {
    auth_type PASS
    auth_pass Vpp123
  }
  virtual_ipaddress {
    ${CLUSTERIP}/22 brd 10.122.223.255 dev eth0
  }
}

vrrp_instance VI_2 {
  state MASTER
  interface eth1
  virtual_router_id 61
  priority 150
  advert_int 1
  nopreempt
  authentication {
    auth_type PASS
    auth_pass Vpp123
  }
  virtual_ipaddress {
    ${VPNCLUSTERIP}/22 brd 10.223.223.255 dev eth1
  }
}
EOL

# Setup the cluster IP
ip address add "${CLUSTERIP}"/22 dev eth0
ip address add "${VPNCLUSTERIP}"/22 dev eth1
iptables -A INPUT -d "${CLUSTERIP}" -i eth0 -j CLUSTERIP --new --hashmode sourceip --clustermac "${CLUSTERMAC}" --total-nodes 2 --local-node 1 --hash-init 0
iptables -A INPUT -d "${VPNCLUSTERIP}" -i eth1 -j CLUSTERIP --new --hashmode sourceip --clustermac "${VPNCLUSTERMAC}" --total-nodes 2 --local-node 1 --hash-init 0

# Start keepalived
keepalived

mkdir -p /etc/ipsec.d/run
ipsec start

# Turn on control of segment one for this node, making it the master
echo +1 > /var/run/charon.ha

# If this script is run via the Dockerfile, we'd want the below at the end. But
# in the case of the ha-scale-vpn containers, we run this script via a "docker
# exec" command after the container is started, so we'll comment this out for
# this use case and leave it here as a note in case someone copies this script.
#tail -f /dev/null
