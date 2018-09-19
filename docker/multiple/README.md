VPP Multiple Container
======================

This directory contains Dockerfiles and configuration to build out multiple
containers running VPP inside of them. It will configure a host interface
on the vpp1 container. A memif will be created on vpp1 as a master, and on
vpp2 as a slave, shared using a volume mountpoint from the host.

The configuration of the container is handled by the `env.list` file found
in this directory. To change this configuration, you can modify this file or
pass these individually on the command line when launching this container.
