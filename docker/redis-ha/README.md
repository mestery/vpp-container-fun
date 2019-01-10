StrongSwan Session Scale Testing
================================

This directory contains Dockerfiles and scripts to build, run and test
the following containers:
* A StrongSwan container with the HA plugin enabled, operating as a
  master node.
* A StrongSwan container with the new JitIke plugin enabled, operating
  as a HA slave and integrating with Redis.
* A redis container.
* A haclient container to run the client VPN.
* A hafarend container running a container behind the VPN.

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
