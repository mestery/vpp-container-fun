# Copyright (c) 2018 Cisco and/or its affiliates.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at:
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# We want to use bash
SHELL:=/bin/bash

# Default target, no other targets should be before default
.PHONY: default
default: all

# Include Makefiles
include docker/cups-vppvpn/Makefile.cups-vppvpn

# Setup proxies for docker build
ifeq ($(HTTP_PROXY),)
HTTPBUILD=
else
HTTPBUILD=--build-arg HTTP_PROXY=$(HTTP_PROXY)
endif
ifeq ($(HTTPS_PROXY),)
HTTPSBUILD=
else
HTTPSBUILD=--build-arg HTTPS_PROXY=$(HTTPS_PROXY)
endif

DOCKERBUILD=docker build ${HTTPBUILD} ${HTTPSBUILD}
DOCKER_VPP_ALLINONE=vpp-container-fun/vpp-allinone
DOCKER_VPP_BASE=vpp-container-fun/base
DOCKER_VPP_MULTIPLE1=vpp-container-fun/multiple-vpp1
DOCKER_VPP_MULTIPLE2=vpp-container-fun/multiple-vpp2
DOCKER_STRONGSWAN_VPP=vpp-container-fun/strongswan-vpp
DOCKER_VPPVPNBASE=vpp-container-fun/vppvpnbase
DOCKER_VPPVPNSERVER=vpp-container-fun/vppvpnserver
DOCKER_VPPVPNCLIENT=vpp-container-fun/vppvpnclient

# The StrongSwan repository and commit to use
BA_STRONGSWAN_REPO_URL=https://github.com/mestery/strongswan.git
BA_STRONGSWAN_COMMIT=vpp-1810

.PHONY: all check docker-build
#
# The all target is what is used by the travis-ci system to build the Docker images
# which are used to run the code in each run.
#
all: check docker-build

check:
	@shellcheck `find . -name "*.sh"`

docker-build: docker-build-allinone docker-build-multiple docker-build-strongswan docker-build-vppvpn docker-build-cups-vppvpn

.PHONY: docker-build-base
docker-build-base:
	@cd docker/base && ${DOCKERBUILD} -t ${DOCKER_VPP_BASE} -f Dockerfile.base .

.PHONY: docker-build-allinone
docker-build-allinone: docker-build-base
	@cd docker/allinone && ${DOCKERBUILD} -t ${DOCKER_VPP_ALLINONE} -f Dockerfile .

.PHONY: docker-build-multiple
docker-build-multiple: docker-build-base
	@cd docker/multiple && ${DOCKERBUILD} -t ${DOCKER_VPP_MULTIPLE1} -f Dockerfile.vpp1 .
	@cd docker/multiple && ${DOCKERBUILD} -t ${DOCKER_VPP_MULTIPLE2} -f Dockerfile.vpp2 .

.PHONY: docker-build-strongswan
docker-build-strongswan: docker-build-base
	@cd docker/strongswan && ${DOCKERBUILD} -t ${DOCKER_STRONGSWAN_VPP} -f Dockerfile.vpp .

.PHONY: docker-build-vppvpnbase
docker-build-vppvpnbase: docker-build-base
	@cd docker/vppvpn && ${DOCKERBUILD} -t ${DOCKER_VPPVPNBASE} -f Dockerfile.strongswan --build-arg STRONGSWAN_REPO_URL=${BA_STRONGSWAN_REPO_URL} --build-arg STRONGSWAN_COMMIT=${BA_STRONGSWAN_COMMIT} .

.PHONY: docker-build-vppvpn
docker-build-vppvpn: docker-build-base docker-build-vppvpnbase
	@cd docker/vppvpn && ${DOCKERBUILD} -t ${DOCKER_VPPVPNSERVER} -f Dockerfile.vpnserver .
	@cd docker/vppvpn && ${DOCKERBUILD} -t ${DOCKER_VPPVPNCLIENT} -f Dockerfile.vpnclient .

# Travis
.PHONY: travis
travis:
	@echo "=> TRAVIS: $$TRAVIS_BUILD_STAGE_NAME"
	@echo "Build: #$$TRAVIS_BUILD_NUMBER ($$TRAVIS_BUILD_ID)"
	@echo "Job: #$$TRAVIS_JOB_NUMBER ($$TRAVIS_JOB_ID)"
	@echo "AllowFailure: $$TRAVIS_ALLOW_FAILURE TestResult: $$TRAVIS_TEST_RESULT"
	@echo "Type: $$TRAVIS_EVENT_TYPE PullRequest: $$TRAVIS_PULL_REQUEST"
	@echo "Repo: $$TRAVIS_REPO_SLUG Branch: $$TRAVIS_BRANCH"
	@echo "Commit: $$TRAVIS_COMMIT"
	@echo "$$TRAVIS_COMMIT_MESSAGE"
	@echo "Range: $$TRAVIS_COMMIT_RANGE"
	@echo "Files:"
	@echo "$$(git diff --name-only $$TRAVIS_COMMIT_RANGE)"

.PHONY: run
run: run-allinone run-multiple run-strongswan run-vppvpn run-cups-vppvpn

.PHONY: run-allinone
run-allinone:
	@docker run --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./docker/allinone/env.list -id --name vppallinone ${DOCKER_VPP_ALLINONE} && sleep 15

.PHONY: run-multiple
run-multiple:
	@mkdir -p run
	@rm -rf run/vpp*
	@docker run -v `pwd`/run:/run --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./docker/multiple/env.list -id --name vpp1 ${DOCKER_VPP_MULTIPLE1} && sleep 15
	@docker run -v `pwd`/run:/run --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./docker/multiple/env.list -id --name vpp2 ${DOCKER_VPP_MULTIPLE2} && sleep 15

.PHONY: run-strongswan
run-strongswan:
	@docker run --cap-add IPC_LOCK --cap-add NET_ADMIN --env-file ./docker/strongswan/env.list -id --name strongswanvpp ${DOCKER_STRONGSWAN_VPP}

.PHONY: run-vppvpn
run-vppvpn:
	@cd ./docker/vppvpn && ./runme.sh ${DOCKER_VPPVPNSERVER} ${DOCKER_VPPVPNCLIENT}

.PHONY: test
test: test-allinone test-multiple test-strongswan test-vppvpn test-cups-vppvpn

.PHONY: test-allinone
test-allinone:
	@docker exec -it vppallinone ping -c 5 10.10.2.2

.PHONY: test-multiple
test-multiple:
	@docker exec -it vpp1 ping -c 5 10.10.2.2

.PHONY: test-strongswan
test-strongswan:
	@docker exec -it strongswanvpp ping 192.168.124.100 -c 5

.PHONT: test-vppvpn
test-vppvpn:
	@docker exec -it vppvpnclient ping 192.168.124.100 -c 5
