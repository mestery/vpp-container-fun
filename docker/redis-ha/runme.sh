#!/bin/bash
#
# The order of what happens here is as follows:
#
# 1. First, we check for the base Docker network the containers will share (defined
#    as DOCKER_NETWORK) and create it if it is not found.
# 2. We then start the HA StrongSwan IKE/ESP containers.
# 3. We next start the StrongSwan client container.
# 4. We now check for the VPN network (defined as VPN_NETWORK) and create it if it
#    is not found.
# 5. We then connect this network up to the HA StrongSwan containers.
# 6. We now run the start scripts on the HA StrongSwan containers and the client
#    StrongSwan container.
# 7. Finally, we start a farend client on the VPN_NETWORK.

# shellcheck disable=SC1091
source env.list

SERVERIMAGE1=$1
SERVERIMAGE2=$2
CLIENTIMAGE=$3
FARENDIMAGE=$4

echo "${DOCKER_NETWORK}"
echo "Looking for ${DOCKER_NETWORK}"
EXISTS="$(docker network ls | grep "${DOCKER_NETWORK}")"
echo "Found this value: ${EXISTS}"

# Check if the docker network exists
if [ "x${EXISTS}" == "x" ] ; then
	docker network create "${DOCKER_NETWORK}" --subnet="${DOCKER_NETWORK_RANGE}"
fi

docker run --privileged --mac-address "${SERVER1_MAC}" --net "${DOCKER_NETWORK}" --ip "${SERVER1_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${SERVER1_NAME}" "${SERVERIMAGE1}"
docker run --privileged --mac-address "${SERVER2_MAC}" --net "${DOCKER_NETWORK}" --ip "${SERVER2_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${SERVER2_NAME}" "${SERVERIMAGE2}"
docker run --privileged --mac-address "${CLIENT_MAC}" --net "${DOCKER_NETWORK}" --ip "${CLIENT_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${CLIENT_NAME}" "${CLIENTIMAGE}"

echo "Looking for ${VPN_NETWORK}"
VPNEXISTS="$(docker network ls | grep "${VPN_NETWORK}")"
echo "Found this value: ${VPNEXISTS}"

# Check if the docker network exists
if [ "x${VPNEXISTS}" == "x" ] ; then
	docker network create "${VPN_NETWORK}" --subnet="${VPN_NETWORK_RANGE}"
fi

# Connect the second network
docker network connect --ip "${VPN1_IP}" "${VPN_NETWORK}" "${SERVER1_NAME}"
docker network connect --ip "${VPN2_IP}" "${VPN_NETWORK}" "${SERVER2_NAME}"

echo "Looking for ${REDIS_NETWORK}"
REDISNETEXISTS="$(docker network ls | grep "${REDIS_NETWORK}")"
echo "Found this value: ${REDISNETEXISTS}"
# Check if the redis network exists
if [ "x${REDISNETEXISTS}" == "x" ] ; then
	docker network create "${REDIS_NETWORK}" --subnet="${REDIS_NETWORK_RANGE}"
fi

# Start the redis container
docker run --name "${REDIS_NAME}" --net "${REDIS_NETWORK}" --ip "${REDIS_SERVER_IP}" -id redis

# Connect the second network
docker network connect --ip "${REDIS_HA1_IP}" "${REDIS_NETWORK}" "${SERVER1_NAME}"
docker network connect --ip "${REDIS_HA2_IP}" "${REDIS_NETWORK}" "${SERVER2_NAME}"

# Now run the up scripts
docker exec -it "${SERVER1_NAME}" /startstrongswan1.sh
docker exec -it "${SERVER2_NAME}" /startstrongswan2.sh
docker exec -it "${CLIENT_NAME}" /startvpnclient.sh

# Start far-end client container
docker run --privileged --net "${VPN_NETWORK}" --ip "${FAR_END_CLIENT_IP}" --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./env.list -id --name "${FAR_END_NAME}" "${FARENDIMAGE}"

echo "Finished"
