# vpp-container-fun

[![Build Status](https://travis-ci.org/mestery/vpp-container-fun.svg?branch=master)](https://travis-ci.org/mestery/vpp-container-fun)
[![GitHub license](https://img.shields.io/badge/license-Apache%20license%202.0-blue.svg)](https://github.com/mestery/vpp-container-fun/blob/master/LICENSE)

VPP for Docker containers
=========================

This repository can build you docker containers with VPP in one of two
configurations:

* A single container with two VPP instances running
* One VPP instance per container

In either case, the configuration looks like the below:

![Network Diagram](images/Connecting_two_vpp_instances_with_memif.png)

The following is the IP configuration of the VPP and host interfaces:

* vpp1:
  * 10.10.2.1
* vpp2:
  * 10.10.2.2
* host interface in the container:
  * 10.10.1.1
* host interface in vpp1:
  * 10.10.1.2

Building, running, testing
==========================

To build, run and test the allinone instance:

```
make docker-build-allinone
make run-allinone
make test-allinone
```

To build, run and test the setup where VPP instances run in their own
containers:

```
make docker-build-multiple
make run-multiple
make test-multiple
```

Starting the containers manually is left as an exercise for the reader.

StrongSwan With VPP
===================

There is another container which will setup and run a simple VPP and StrongSwan
test.

To build, run, and test this, do the following:

```
make docker-build-strongswan
make run-strongswan
make test-strongswan
```

The above will build a configuration per the diagram below:

```
               +---------------+                +----------------+      +-------+
               |               | 10.10.1.0/24   |                |      |       | 10.10.10.10
192.168.125.100| StrongSwan    |                | VPP Responder  +------+IPSec  |
               | Initiator     +----------------+                |      +-------+
               |               |                |                |
               +---------------+ .2          .1 |                |      +-------+
                                                |                +------+       | 192.168.124.100
                                                +----------------+      |loop0  |
                                                                        +-------+
```

StrongSwan With Integrated VPP
==============================

A second set of containers will run StrongSwan with integrated VPP charon
drivers to allow VPP to drive the ipsec dataplane.

To build, run, and test this, do the following:

```
make docker-build-vppvpn
make run-vppvpn
make test-vppvpn
```

This builds the following configuration:

```
+------------------------------------------------------------------------------------------------+
| Linux VM                                                                                       |
|                               +--------------------------------------------------------------+ |
|                               | StrongSwan Server and VPP Container                          | |
|                               |                                                              | |
|  +------------------------+   |  +----------------------------------------+                  | |
|  | StrongSwan Initiator   |   |  | VPP  +----------+     +----------+     |                  | |
|  | Container              |   |  |      | VPP      |     | IPSEC    |     |                  | |
|  |                        |   |  |      | Routing  |     | Dataplane|     |                  | |
|  |                        |   |  |      +----------+     +----------+     |                  | |
|  |                        |   |  |                                        |  +-------------+ | |
|  |                        |   |  | +---------------+    +---------------+ |  | StrongSwan  | | |
|  |                        |   |  | |192.168.124.100|    |10.10.1.2      | |  | Control     | | |
|  |                        |   |  | | gw-net tap    |    | gateway tap   | |  | Plane       | | |
|  |                        |   |  | +---------------+    +---------------+ |  +-------------+ | |
|  |                        |   |  +----------------------------------------+                  | |
|  |                        |   |          |                        |                          | |
|  |                        |   | +--------+------+         +-------+-------+                  | |
|  |                        |   | |192.168.124.200|         |10.10.1.1      |                  | |
|  |                        |   | |               |         |               |                  | |
|  |                        |   | | ns2 namespace |         | default ns    |                  | |
|  |                        |   | +---------------+         +---------------+                  | |
|  |      +--------+        |   |                          +--------+                          | |
|  |      |  eth0  |        |   |                          |  eth0  |                          | |
|  +------+---+----+--------+   +--------------------------+----+---+--------------------------+ |
|             |                                                 |                                |
|     10.200.200.100                                    10.200.200.50                            |
|             |                                                 |                                |
|             |                                                 |                                |
|             |           +--------------------------+          |                                |
|             |           |                          |          |                                |
|             +-----------+                          +----------+                                |
|                         |     docker0 bridge       |                                           |
|                         |                          |                                           |
|                         +--------------------------+                                           |
|                                                                                                |
+------------------------------------------------------------------------------------------------+
```

StrongSwan HA Scale VPN
=======================

See the [README.md](docker/ha-scale-vpn/README.md) for more information.
