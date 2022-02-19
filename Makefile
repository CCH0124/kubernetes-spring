.PHONY: build-image push-image helm kustomize native

SERVER  =
REPO    ?=cch0124/cicd-spring
COMMIT  =${shell git rev-parse --short HEAD}
LOG     ="${shell git log -1 --pretty=%B}"
VERSION ?=${COMMIT}
TYPE    ?=KIND

build-image:
        docker build --tag ${SERVER}${REPO}:${VERSION} .
        docker image tag ${SERVER}${REPO}:${VERSION} ${SERVER}${REPO}:latest

push-image: build-image
        docker image push ${SERVER}${REPO}:${VERSION}
        docker image push ${SERVER}${REPO}:latest