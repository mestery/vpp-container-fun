#!/bin/bash

set -xe

# Add the route back
ip route add "${DOCKER_NETWORK_RANGE}" via "${VPNCLUSTERIP}"

# We do not want to exit, so ...
tail -f /dev/null
