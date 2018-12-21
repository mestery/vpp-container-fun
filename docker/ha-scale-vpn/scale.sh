#!/bin/bash
#
# This script is used to scale test the StrongSwan IKE/ESP HA nodes. It will
# create a network namespace, copy over some ipsec configuration files, and
# setup some IP addresses in the network namespace before starting an ipsec
# client. You can change how many of these are created by setting COUNT.

COUNT=5
NSPREFIX=vpn

start() {
  until [ "${COUNT}" -eq "0" ] ; do
    NSPACE="${NSPREFIX}-${COUNT}"
    NDEV="${NSPACE}"-dev

    ip netns add "${NSPACE}"
    mkdir -p /etc/netns/"${NSPACE}"/ipsec.d/run
    ip link add link eth0 name "${NDEV}" type macvtap mode bridge
    ip link set dev "${NDEV}" netns "${NSPACE}" up
    ip netns exec "${NSPACE}" ip link set dev lo up
    ip netns exec "${NSPACE}" ip address add 10.122.220."${COUNT}"/22 dev "${NDEV}"

    cat >/etc/netns/"${NSPACE}"/ipsec.conf << EOL
config setup
        strictcrlpolicy=no

conn %default
        #ike=aes256-sha1-modp2048!
        esp=aes128gcm8
        mobike=no
        keyexchange=ikev2
        ikelifetime=24h
        lifetime=24h

conn vpn-${NSPACE}
        type=tunnel
        right=${CLUSTERIP}
        rightsubnet=${VPN_SUBNET}/${VPN_SUBNET_MASK}
        rightauth=psk
        left=10.122.220.${COUNT}
        leftauth=psk
        auto=add
EOL

    cp /etc/ipsec.secrets /etc/netns/"${NSPACE}"/ipsec.secrets

    ip netns exec "${NSPACE}" ipsec start --conf /etc/netns/"${NSPACE}"/ipsec.conf
    ip netns exec "${NSPACE}" ipsec up vpn-${NSPACE}
    ip netns exec "${NSPACE}" ipsec statusall

    COUNT=$(( COUNT - 1 ))
  done
}

stop() {
  until [ "${COUNT}" -eq "0" ] ; do
    NSPACE="${NSPREFIX}-${COUNT}"
    NDEV="${NSPACE}"-dev

    ip netns exec "${NSPACE}" ipsec stop
    ip netns exec "${NSPACE}" ip link delete dev "${NDEV}" type mcvtap
    ip netns delete "${NSPACE}"

    rm -f /etc/netns/"${NSPACE}"/ipsec.d/run/*

    COUNT=$(( COUNT - 1 ))
  done
}

status() {
  local f

  for f in $(seq 1 "${COUNT}") ; do
    ip netns exec "vpn-${f}" ipsec status
  done
}

statusall() {
  local f

  for f in $(seq 1 "${COUNT}") ; do
    ip netns exec "vpn-${f}" ipsec statusall
  done
}

pingall() {
  local f

  for f in $(seq 1 "${COUNT}") ; do
    ip netns exec "vpn-${f}" ping -c 5 "${VPNCLUSTERIP}"
  done
}

if [ "$1" == "start" ] ; then
  start
elif [ "$1" == "stop" ] ; then
  stop
elif [ "$1" == "status" ] ; then
  status
elif [ "$1" == "statusall" ] ; then
  statusall
else
  echo "Usage: [start | stop | status | statusall | pingall]"
fi
