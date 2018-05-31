SHELL      := /usr/bin/env bash
ARGS			 := $(filter-out $@,$(MAKECMDGOALS))
IMAGE_ORG  := ea31337
IMAGE_NAME := fx-mt-vm
DOCKER_TAG := latest
DOCKER_TAR := ${HOME}/.docker/images.tar.gz
DOCKER_CFG := ${HOME}/.docker/config.json
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
BUILD_VREF := $(shell git rev-parse --short HEAD)
.PHONY: docker-load docker-build docker-login docker-tag docker-pull docker-push docker-run docker-save docker-clean
docker-ci: docker-load docker-build docker-save
docker-load:
	if [[ -f $(DOCKER_TAR) ]]; then gzip -dc $(DOCKER_TAR) | docker load; fi
docker-build:
	docker build -t ${IMAGE_NAME}:$(DOCKER_TAG) --build-arg BUILD_DATE=$(BUILD_DATE) --build-arg VCS_REF=$(BUILD_VREF) --build-arg VERSION=$(DOCKER_TAG) .
docker-login:
	if [[ "$(DOCKER_PASSWORD)" ]]; then docker login -u $(DOCKER_USERNAME) --password-stdin <<<"$(DOCKER_PASSWORD)"; fi
docker-tag:
	docker tag ${IMAGE_NAME}:$(DOCKER_TAG) $(IMAGE_ORG)/$(IMAGE_NAME):$(DOCKER_TAG)
docker-pull:
	docker pull $(IMAGE_ORG)/$(IMAGE_NAME):$(DOCKER_TAG)
docker-push: docker-login docker-tag
	docker images
	docker push $(IMAGE_ORG)/$(IMAGE_NAME):$(DOCKER_TAG)
docker-run:
	docker run -it ${IMAGE_NAME} bash
docker-save:
	docker save ${IMAGE_NAME} | gzip > $(DOCKER_TAR)
docker-clean:
	docker system prune -af
