SHELL := /bin/bash
ALL: build
ORIG_IMG := php
IMAGE := m0bua/php
VERSION ?= latest
PUSH_VER := $(VERSION)
DEV := $(shell v="${VERSION}\n7"; [[ "`printf $${v}`" != "`printf $${v} | sort -V`" ]] && echo "true")

build:
	@echo "=====> Building image..."; \
	docker image build --quiet -t $(IMAGE):$(PUSH_VER) . --build-arg IMAGE=$(ORIG_IMG):$(VERSION);
	@if [[ ! -z "$(DEV)" ]]; then \
		echo "=====> Building dev image..."; \
		docker image build --quiet -t $(IMAGE):$(PUSH_VER)-dev dev --build-arg IMAGE=$(IMAGE):$(PUSH_VER); \
	fi;

test:
	@echo "=====> Testing image..."; \
	if [[ -z "`docker image ls $(IMAGE) | grep "\s${PUSH_VER}\s"`" ]]; \
		then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER) ]"; exit 1; fi; \
	echo 'OK'; \
	echo "=====> Testing composer..."; \
	if [[ -z `docker container run --rm $(IMAGE):$(PUSH_VER) composer --version 2> /dev/null \
			| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; exit 1; fi; \
	echo 'OK'
	@if [[ ! -z "$(DEV)" ]]; then \
		echo "=====> Testing dev image..."; \
		if [[ -z "`docker image ls $(IMAGE) | grep "\s${PUSH_VER}-dev\s"`" ]]; \
			then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER)-dev ]"; exit 1; fi; \
		echo 'OK'; \
		echo "=====> Testing dev composer..."; \
		if [[ -z `docker container run --rm $(IMAGE):$(PUSH_VER)-dev composer --version 2> /dev/null \
				| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
			echo 'FAIL [Composer]'; exit 1; fi; \
		echo 'OK'; fi

push:
	@echo "=====> Pushing container..."; \
	docker image push $(IMAGE):$(PUSH_VER); \
	echo 'OK'
	@echo "=====> Pushing dev container..."; \
	docker image push $(IMAGE):$(PUSH_VER)-dev; \
	echo 'OK'
