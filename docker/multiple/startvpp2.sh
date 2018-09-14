#!/bin/bash

set -xe

# Run the VPP daemons
/usr/bin/vpp -c /etc/vpp/startup2.conf

typeset -i cnt=60
until ls -l /run/vpp/cli-vpp2.sock ; do
       ((cnt=cnt-1)) || return 1
       sleep 1
done

# We do not want to exit, so ...
tail -f /dev/null
