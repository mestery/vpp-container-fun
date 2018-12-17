#!/bin/bash

set -xe

mv /etc/strongswan.d/charon-logging.conf /etc/strongswan.d/charon-logging.conf.old
cat > /etc/strongswan.d/charon-logging.conf << EOL
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

# Configure HA mode
cat > /etc/strongswan.d/charon/ha.conf << EOL
ha {
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
    local = ${SERVER2_IP}
    monitor = yes
    # pools =
    remote = ${SERVER1_IP}
    resync = yes
    # secret =
    segment_count = 1

}
EOL

cat >/tmp/ipsec.conf << EOL
config setup
        strictcrlpolicy=no

conn %default
        mobike=no
        keyexchange=ikev2
        ikelifetime=24h
        lifetime=24h

conn net-net
        type=tunnel
        left=${CLUSTERIP}
        leftsubnet=${VPN_SUBNET}/${VPN_SUBNET_MASK}
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

vrrp_instance VI_1 {
  state BACKUP
  interface eth0
  virtual_router_id 51
  priority 100
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass Vpp123
  }
  virtual_ipaddress {
    ${CLUSTERIP}/22 brd 10.122.223.255 dev eth0
  }
  notify /etc/keepalived/notifyipsec.sh
}

vrrp_instance VI_2 {
  state BACKUP
  interface eth1
  virtual_router_id 61
  priority 100
  advert_int 1
  authentication {
    auth_type PASS
    auth_pass Vpp123
  }
  virtual_ipaddress {
    ${VPNCLUSTERIP}/22 brd 10.223.223.255 dev eth1
  }
}
EOL

cat > /etc/keepalived/notifyipsec.sh << EOL
#!/bin/bash

TYPE=$1
NAME=$2
STATE=$3

case $STATE in
    "MASTER") ipsec restart
              exit 0
              ;;
    "BACKUP") ipsec stop
              exit 0
              ;;  
    "FAULT")  ipsec stop
              exit 0
              ;;
    *)        echo "unknown state"
              exit 1
              ;;
esac
EOL

# Setup the cluster IP
iptables -A INPUT -d "${CLUSTERIP}" -i eth0 -j CLUSTERIP --new --hashmode sourceip --clustermac "${CLUSTERMAC}" --total-nodes 2 --local-node 2 --hash-init 0
iptables -A INPUT -d "${VPNCLUSTERIP}" -i eth1 -j CLUSTERIP --new --hashmode sourceip --clustermac "${VPNCLUSTERMAC}" --total-nodes 2 --local-node 2 --hash-init 0

# Start keepalived
keepalived

mkdir -p /etc/ipsec.d/run
ipsec start --debug-all

# If this script is run via the Dockerfile, we'd want the below at the end. But
# in the case of the ha-scale-vpn containers, we run this script via a "docker
# exec" command after the container is started, so we'll comment this out for
# this use case and leave it here as a note in case someone copies this script.
#tail -f /dev/null
