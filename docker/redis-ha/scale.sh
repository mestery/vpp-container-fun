#!/bin/bash
#
# This script is used to scale test the StrongSwan IKE/ESP HA nodes. It will
# create a network namespace, copy over some ipsec configuration files, and
# setup some IP addresses in the network namespace before starting an ipsec
# client. You can change how many of these are created by setting MAXCOUNT.

# The maximum number of iterations to make in this script
MAXCOUNT=5
COUNT=1
NSPREFIX=vpn

# Converst a decimal into an IP address
dec2ip () {
    local ip dec=( "$@" )
    for e in {3..0}
    do
        ((octet = dec / (256 ** e) ))
        ((dec -= octet * 256 ** e))
        ip+=$delim$octet
        delim=.
    done
    printf '%s\n' "$ip"
}

# Converts an IP address into a decimal
ip2dec () {
    local a b c d ip=( "$@" )
    IFS=. read -r a b c d <<< "${ip[@]}"
    printf '%d\n' "$((a * 256 ** 3 + b * 256 ** 2 + c * 256 + d))"
}

# The start IP address.
# .FIXME: Should probably source env.sh from the same directory and get it
#         from there rather than hard coding here.
STARTIP=10.122.220.1
# The decimal version of the above
ADDRESS=$(ip2dec ${STARTIP})

start() {
  while [ "${COUNT}" -le "${MAXCOUNT}" ]; do
    VPNCADDR=$(dec2ip "$ADDRESS")
    NSPACE="${NSPREFIX}-${COUNT}"
    NDEV="${NSPACE}"-dev

    OCTET=$(echo "${VPNCADDR}" | cut -d . -f 4)
    if [ "$OCTET" == "0" ] || [ "${OCTET}" == "255" ] ; then
      ADDRESS=$(( ADDRESS + 1 ))
      COUNT=$(( COUNT + 1 ))
      continue
    fi

    ip netns add "${NSPACE}"
    mkdir -p /etc/netns/"${NSPACE}"/ipsec.d/run
    ip link add link eth0 name "${NDEV}" type macvtap mode bridge
    ip link set dev "${NDEV}" netns "${NSPACE}" up
    ip netns exec "${NSPACE}" ip link set dev lo up
    ip netns exec "${NSPACE}" ip address add "${VPNCADDR}"/22 dev "${NDEV}"

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
        left=${VPNCADDR}
        leftauth=psk
        auto=add
EOL

    cp /etc/ipsec.secrets /etc/netns/"${NSPACE}"/ipsec.secrets

    ip netns exec "${NSPACE}" ipsec start --conf /etc/netns/"${NSPACE}"/ipsec.conf
    ip netns exec "${NSPACE}" ipsec up vpn-${NSPACE}
    ip netns exec "${NSPACE}" ipsec statusall

    ADDRESS=$(( ADDRESS + 1 ))
    COUNT=$(( COUNT + 1 ))
  done
}

stop() {
  while [ "${COUNT}" -le "${MAXCOUNT}" ]; do
    VPNCADDR=$(dec2ip $ADDRESS)
    NSPACE="${NSPREFIX}-${COUNT}"
    NDEV="${NSPACE}"-dev

    OCTET=$(echo "${VPNCADDR}" | cut -d . -f 4)
    if [ "$OCTET" == "0" ] || [ "${OCTET}" == "255" ] ; then
      ADDRESS=$(( ADDRESS + 1 ))
      COUNT=$(( COUNT + 1 ))
      continue
    fi

    ip netns exec "${NSPACE}" ipsec stop
    ip netns exec "${NSPACE}" ip link delete dev "${NDEV}" type mcvtap
    ip netns delete "${NSPACE}"

    rm -f /etc/netns/"${NSPACE}"/ipsec.d/run/*

    ADDRESS=$(( ADDRESS + 1 ))
    COUNT=$(( COUNT + 1 ))
  done
}

status() {
  while [ "${COUNT}" -le "${MAXCOUNT}" ]; do
    VPNCADDR=$(dec2ip $ADDRESS)
    OCTET=$(echo "${VPNCADDR}" | cut -d . -f 4)
    if [ "$OCTET" == "0" ] || [ "${OCTET}" == "255" ] ; then
      ADDRESS=$(( ADDRESS + 1 ))
      COUNT=$(( COUNT + 1 ))
      continue
    fi

    ip netns exec "vpn-${COUNT}" ipsec status

    ADDRESS=$(( ADDRESS + 1 ))
    COUNT=$(( COUNT + 1 ))
  done
}

statusall() {
  while [ "${COUNT}" -le "${MAXCOUNT}" ]; do
    VPNCADDR=$(dec2ip $ADDRESS)
    OCTET=$(echo "${VPNCADDR}" | cut -d . -f 4)
    if [ "$OCTET" == "0" ] || [ "${OCTET}" == "255" ] ; then
      ADDRESS=$(( ADDRESS + 1 ))
      COUNT=$(( COUNT + 1 ))
      continue
    fi
    ip netns exec "vpn-${COUNT}" ipsec statusall

    ADDRESS=$(( ADDRESS + 1 ))
    COUNT=$(( COUNT + 1 ))
  done
}

pingall() {
  while [ "${COUNT}" -le "${MAXCOUNT}" ]; do
    VPNCADDR=$(dec2ip $ADDRESS)
    OCTET=$(echo "${VPNCADDR}" | cut -d . -f 4)
    if [ "$OCTET" == "0" ] || [ "${OCTET}" == "255" ] ; then
      ADDRESS=$(( ADDRESS + 1 ))
      COUNT=$(( COUNT + 1 ))
      continue
    fi
    ip netns exec "vpn-${COUNT}" ping -c 5 "${VPNCLUSTERIP}"

    ADDRESS=$(( ADDRESS + 1 ))
    COUNT=$(( COUNT + 1 ))
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
elif [ "$1" == "pingall" ] ; then
  pingall
else
  echo "Usage: [start | stop | status | statusall | pingall]"
fi
