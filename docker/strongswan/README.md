VPP and StrongSwan Docker Container
===================================

This directory contains the Dockerfile and configuration to build a Docker
container for VPP and StrongSwan. Specifically, it builds a single container
which will run VPP, including creating a VPP host interface to link VPP to
the container itself. From there, it runs strongswan inside the container
as well, and creates a tunnel between them.

The configuration of the container is handled by the `env.list` file found
in this directory. To change this configuration, you can modify this file or
pass these individually on the command line when launching this container.

The configuration roughly follows what is found on
[this](https://wiki.fd.io/view/VPP/IPSec_and_IKEv2#IPSec) wiki page.
