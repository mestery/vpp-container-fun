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
    ip netns exec "${NSPACE}" ip address add 10.222.222."${COUNT}"/24 dev "${NDEV}"

    < /etc/ipsec.conf sed '/left\=/d' > /etc/netns/"${NSPACE}"/ipsec.conf
    echo "        left=10.222.222.${COUNT}" >> /etc/netns/"${NSPACE}"/ipsec.conf
    cp /etc/ipsec.secrets /etc/netns/"${NSPACE}"/ipsec.secrets

    ip netns exec "${NSPACE}" ipsec start --conf /etc/netns/"${NSPACE}"/ipsec.conf
    ip netns exec "${NSPACE}" ipsec up net-net
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

if [ "$1" == "start" ] ; then
  start
elif [ "$1" == "stop" ] ; then
  stop
else
  echo "Usage: [start | stop]"
fi
