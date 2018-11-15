#!/bin/bash

# shellcheck disable=SC1091
source env.list

CUPSSERVERIMAGE=$1
CUPSCLIENTIMAGE=$2
IPSECCLIENTIMAGE=$3

echo "${VPP_DOCKER_NETWORK}"

echo "Looking for ${VPP_DOCKER_NETWORK}"

EXISTS="$(docker network ls | grep "${VPP_DOCKER_NETWORK}")"

echo "Found this value: ${EXISTS}"

# Check if the docker network exists
if [ "x${EXISTS}" == "x" ] ; then
	docker network create "${VPP_DOCKER_NETWORK}" --subnet="${VPP_DOCKER_NETWORK_RANGE}"
fi

docker run --ipc=shareable -p "${VPP_SERVER_PORT}":"${VPP_SERVER_PORT}" --privileged --mac-address "${VPP_SERVER_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_SERVER_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${VPP_SERVER_NAME}" "${CUPSSERVERIMAGE}"

docker run --ipc=container:"${VPP_SERVER_NAME}" -p "${VPP_SSWAN_PORT}":"${VPP_SSWAN_PORT}" -p "${VPP_SSWAN_PORT_TWO}":"${VPP_SSWAN_PORT_TWO}" --privileged --mac-address "${VPP_SWAN_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_SSWAN_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${VPP_SSWAN_NAME}" "${CUPSCLIENTIMAGE}"

docker run --mac-address "${VPP_CLIENT_MAC}" --net "${VPP_DOCKER_NETWORK}" --ip "${VPP_CLIENT_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${VPP_CLIENT_NAME}" "${IPSECCLIENTIMAGE}"

echo "Finished"
