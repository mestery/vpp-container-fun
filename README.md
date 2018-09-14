# vpp-container-fun

[![Build Status](https://travis-ci.org/mestery/vpp-container-fun.svg?branch=master)](https://travis-ci.org/mestery/vpp-container-fun)
[![GitHub license](https://img.shields.io/badge/license-Apache%20license%202.0-blue.svg)](https://github.com/mestery/vpp-container-fun/blob/master/LICENSE)

VPP for Docker containers, with some Kubernetes for fun

This will build a docker container which will run two instances of vpp. They
will be connected over memif interfaces. In addition, it creates a host
interface from the container itself into vpp1. The following is a diagram of
what this looks like:

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


To build these:

```
make docker-build
```

To run the tests:

```
make test
```

If you want to manually start the container, do the following on a Linux host
with Docker:

```
docker run --cap-add IPC_LOCK --cap-add NET_ADMIN -id --name vpp vpp-container-fun/vpp
```

To manually start the container on a Docker for Mac, the IPC_LOCK capability is not
required (though it will work if you add it):

```
docker run --cap-add NET_ADMIN -itd --name vpp vpp-container-fun/vpp
```

To explore the containers and run vppctl by hand:

```
docker exec -it vpp bash
vppctl -s /run/vpp/cli-vpp1.sock
```
