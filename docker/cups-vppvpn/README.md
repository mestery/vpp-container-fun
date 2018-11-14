VPP and StrongSwan Docker Container
===================================

This directory contains the Dockerfiles to build and run two containers:
* One container contains CentOS Linux and runs an ipsec client
* Two containers comprise the ipsec server:
  * One container runs StrongSwan with the VPP integration changes.
  * Another container runs VPP.
  * These containers are connected via punt sockets using socat, and a
    shared volume for the VPP API to use for shared memory.

The configuration of the container is handled by the `env.list` file found
in this directory. To change this configuration, you can modify this file or
pass these individually on the command line when launching this container.

The configuration roughly follows what is found on
[this](https://software.intel.com/en-us/articles/get-started-with-ipsec-acceleration-in-the-fdio-vpp-project)
page.
