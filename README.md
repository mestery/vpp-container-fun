# vpp-container-fun

[![Build Status](https://travis-ci.org/mestery/vpp-container-fun.svg?branch=master)](https://travis-ci.org/mestery/vpp-container-fun)
[![GitHub license](https://img.shields.io/badge/license-Apache%20license%202.0-blue.svg)](https://github.com/mestery/vpp-container-fun/blob/master/LICENSE)

VPP for Docker containers, with some Kubernetes for fun

This will build a docker container which will run two instances of vpp. They
will be connected over memif interfaces with the following IP configuration:

* vpp1:
  * 10.10.2.1
* vpp2:
  * 10.10.2.2

To build these:

```
cd docker
docker build -t vpp-container-fun/vpp -f Dockerfile .
```

To start the container:

```
docker run -itd --name vpp vpp-container-fun/vpp
```

To explore the containers:

```
docker exec -it vpp bash
vppctl -s /run/vpp/cli-vpp1.sock
```
