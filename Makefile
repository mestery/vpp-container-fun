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
DOCKER_VPP_MULTIPLE_BASE=vpp-container-fun/multiple-base
DOCKER_VPP_MULTIPLE1=vpp-container-fun/multiple-vpp1
DOCKER_VPP_MULTIPLE2=vpp-container-fun/multiple-vpp2

.PHONY: all check docker-build
#
# The all target is what is used by the travis-ci system to build the Docker images
# which are used to run the code in each run.
#
all: check docker-build

check:
	@shellcheck `find . -name "*.sh"`

docker-build: docker-build-allinone

.PHONY: docker-build-allinone
docker-build-allinone:
	@cd docker/allinone && ${DOCKERBUILD} -t ${DOCKER_VPP_ALLINONE} -f Dockerfile .

.PHONY: docker-build-multiple
docker-build-multiple:
	@cd docker/multiple && ${DOCKERBUILD} -t ${DOCKER_VPP_MULTIPLE_BASE} -f Dockerfile.base .
	@cd docker/multiple && ${DOCKERBUILD} -t ${DOCKER_VPP_MULTIPLE1} -f Dockerfile.vpp1 .
	@cd docker/multiple && ${DOCKERBUILD} -t ${DOCKER_VPP_MULTIPLE2} -f Dockerfile.vpp2 .

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
run: run-allinone run-multiple

.PHONY: run-allinone
run-allinone:
	@docker run --cap-add IPC_LOCK --cap-add NET_ADMIN -id --name vppallinone ${DOCKER_VPP_ALLINONE} && sleep 15

.PHONY: run-multiple
run-multiple:
	@mkdir -p run
	@rm -rf run/vpp*
	@docker run -v `pwd`/run:/run --cap-add IPC_LOCK --cap-add NET_ADMIN -id --name vpp1 ${DOCKER_VPP_MULTIPLE1} && sleep 15
	@docker run -v `pwd`/run:/run --cap-add IPC_LOCK --cap-add NET_ADMIN -id --name vpp2 ${DOCKER_VPP_MULTIPLE2} && sleep 15

.PHONY: test
test: test-allinone test-multiple

.PHONY: test-allinone
test-allinone:
	@docker exec -it vppallinone ping -c 5 10.10.2.2

.PHONY: test-multiple
test-multiple:
	@docker exec -it vpp1 ping -c 5 10.10.2.2
