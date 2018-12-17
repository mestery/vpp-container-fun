StrongSwan Session Scale Testing
================================

This directory contains Dockerfiels to build and run four containers:
* Two StrongSwan IKE/ESP nodes running in active-active HA mode. These
  use keepalived for the VIP shared between the two.
* A single vpnclient container which runs the StrongSwan client.
* A "farend" container which sits behind the VPN tunnels front-ended by
  the IKE/ESP nodes.

These do not run VPP, they use the standard StrongSwan Linux kernel
dataplanes.

Note that in the client container, we use network namespaces to run a
per-client ipsec. That configuration is handled roughly by the instructions
found [here](https://wiki.strongswan.org/projects/strongswan/wiki/Netns#Running-strongSwan-Inside-a-Network-Namespace).
The HA configuration for StrongSwan is based on the examples found on
[this page](https://wiki.strongswan.org/projects/strongswan/wiki/HighAvailability).

The configuration of the container is handled by the `env.list` file found
in this directory. To change this configuration, you can modify this file or
pass these individually on the command line when launching this container.

The configuration roughly follows what is found on
[this](https://software.intel.com/en-us/articles/get-started-with-ipsec-acceleration-in-the-fdio-vpp-project)
page.
