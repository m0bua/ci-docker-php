SHELL := /bin/bash
ALL: build
VERSION ?= latest
ORIG_IMG := php
IMAGE := m0bua/php
PUSH_VER := $(VERSION)
CLEAN_PWD := $(PASSWORD)

build:
	@echo "=====> Building image..."; \
	docker image build --quiet -t $(IMAGE):$(PUSH_VER) . --build-arg IMAGE=$(ORIG_IMG):$(VERSION); \
	echo 'OK'

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

push:
	@echo "=====> Pushing container..."; \
	docker image push $(IMAGE):$(PUSH_VER); \
	echo 'OK'

clean:
	@echo "=====> Cleaning old images..."; \
	link='https://hub.docker.com/v2/repositories/$(IMAGE)/tags'; \
	list=`curl -s $$link?ordering=-last_updated | jq -r .results`; \
	for i in `echo $$list | jq -cr .[]`; do \
		name=`echo $$i | jq -r .name`; \
		date=`echo $$i | jq -r .last_updated`; \
		[[ `date +%F -d $$date` < `date +%F` ]] && \
		curl -s -X DELETE -H "Authorization: JWT $(CLEAN_PWD)" $$link/$$name; \
	done; \
	echo 'OK'
