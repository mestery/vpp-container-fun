#!/bin/bash

# shellcheck disable=SC1091
source env.list

SERVERIMAGE=$1
CLIENTIMAGE=$2

echo "${VPP_DOCKER_NETWORK}"

echo "Looking for ${VPP_DOCKER_NETWORK}"

EXISTS="$(docker network ls | grep "${VPP_DOCKER_NETWORK}")"

echo "Found this value: ${EXISTS}"

# Check if the docker network exists
if [ "x${EXISTS}" == "x" ] ; then
	docker network create "${VPP_DOCKER_NETWORK}" --subnet="${VPP_DOCKER_NETWORK_RANGE}"
fi

#docker run --sysctl net.ipv4.conf.all.proxy_arp=1 --mac-address "${VPP_SERVER_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_SERVER_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name vppvpnserver ${SERVERIMAGE}
docker run --mac-address "${VPP_SERVER_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_SERVER_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name vppvpnserver "${SERVERIMAGE}"
docker run --mac-address "${VPP_CLIENT_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_CLIENT_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name vppvpnclient "${CLIENTIMAGE}"

echo "Finished"
