SHELL      := /usr/bin/env bash
ARGS			 := $(filter-out $@,$(MAKECMDGOALS))
IMAGE_PATH := ea31337/fx-mt-vm
DOCKER_TAG := latest
DOCKER_TAR := ${HOME}/.docker/images.tar.gz
DOCKER_CFG := ${HOME}/.docker/config.json
.PHONY: docker-load docker-build docker-push docker-run docker-save docker-clean
docker-ci: docker-load docker-build docker-save
docker-load:
	if [[ -f $(DOCKER_TAR) ]]; then gzip -dc $(DOCKER_TAR) | docker load; fi
docker-build:
	docker build -t $(IMAGE_PATH):$(DOCKER_TAG) .
docker-login:
	if [[ -z "$(DOCKER_PASSWORD)" ]]; then if [[ ! -f "$(DOCKER_CFG)" ]]; then docker login -u $(DOCKER_USERNAME) --password-stdin <<<"$(DOCKER_PASSWORD)"; fi; fi
docker-pull:
	docker pull $(IMAGE_PATH):$(DOCKER_TAG)
docker-push: docker-login
	docker push $(IMAGE_PATH):$(DOCKER_TAG)
docker-run:
	docker run -it $(IMAGE_PATH) /fx-mt-vm bash
docker-save:
	docker save $(IMAGE_PATH) | gzip > ~/.docker/images.tar
docker-clean:
	docker system prune -af
