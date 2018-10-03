VPP and StrongSwan Docker Container
===================================

This directory contains the Dockerfiles to build and run two containers:
* One container contains CentOS Linux and runs a custom built strongswan.
* A second container contains CentOS Linux, also with strongswan, but
  using the VPP charon drivers, thus using VPP as the ipsec dataplane.

The configuration of the container is handled by the `env.list` file found
in this directory. To change this configuration, you can modify this file or
pass these individually on the command line when launching this container.

The configuration roughly follows what is found on
[this](https://software.intel.com/en-us/articles/get-started-with-ipsec-acceleration-in-the-fdio-vpp-project)
page.
