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
