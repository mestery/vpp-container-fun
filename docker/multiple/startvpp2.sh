#!/bin/bash

set -xe

# Generate the config file
cat > /etc/vpp/config2.txt << EOL
create interface memif id 0 slave
set in state memif0/0 up
set int ip address memif0/0 ${VPP2MEMIFIP}/${VPP2MEMIFMASK}
ip route add ${HOSTROUTE}/${HOSTMASK} via ${VPP1MEMIFIP}
EOL

# Run the VPP daemons
/usr/bin/vpp -c /etc/vpp/startup2.conf

typeset -i cnt=60
until ls -l /run/vpp/cli-vpp2.sock ; do
       ((cnt=cnt-1)) || return 1
       sleep 1
done

# We do not want to exit, so ...
tail -f /dev/null
