SHELL     := /usr/bin/env bash
IMAGE_TAG := ea31337/fx-mt-vm
IMAGE_TAR := ${HOME}/.docker/images.tar
DOCKR_CFG := ${HOME}/.docker/config.json
.PHONY: docker-load docker-build docker-push docker-run docker-save docker-clean
docker-ci: docker-load docker-build docker-push docker-save
docker-load:
	if [[ -f $(IMAGE_TAR) ]]; then docker load -i $(IMAGE_TAR); fi
docker-build:
	docker build -t $(IMAGE_TAG) .
docker-login:
	if [[ ! -f $(DOCKR_CFG) ]]; then docker login -u $(DOCKER_USERNAME) --password-stdin <<<$(DOCKER_PASSWORD); fi
docker-push: docker-login
	docker push $(IMAGE_TAG)
docker-run:
	docker run -it ea31337/fx-mt-vm bash
docker-save:
	docker save ea31337/fx-mt-vm -o ~/.docker/images.tar
docker-clean:
	docker system prune -af
