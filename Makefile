SHELL := /bin/bash
ALL: build
.PHONY: build test push

ORIG_IMG := php
IMAGE := m0bua/php
VERSION ?= latest
PUSH_VER := $(VERSION)

EXTENSIONS := bcmath bz2 calendar exif intl gd ldap memcached OPcache pdo_mysql pdo_pgsql pgsql redis soap xsl zip sockets imagick
EXT_EXTRA_CHECK := iconv mbstring

PHP_MCRYPT := $(shell v="${VERSION}\n7.2"; [[ "`printf $${v}`" != "`printf $${v} | sort -V`" ]] && echo "true")
ifeq "$(PHP_MCRYPT)" "true"
	EXTENSIONS += mcrypt
endif
PHP_MYSQLI := $(shell v="${VERSION}\n7"; [[ "`printf $${v}`" != "`printf $${v} | sort -V`" ]] && echo "true")
ifeq "$(PHP_MYSQLI)" "true"
	EXTENSIONS += mysqli
endif

build:
	@echo "=====> Building image..."
	@ext="$(EXTENSIONS)"; docker image build --quiet -t $(IMAGE):$(PUSH_VER) . \
		--build-arg IMAGE=$(ORIG_IMG):$(VERSION) --build-arg EXTENSIONS="$${ext,,}";
	@docker image build --quiet -t $(IMAGE):$(PUSH_VER)-dev dev \
		--build-arg IMAGE=$(IMAGE):$(PUSH_VER);

test:
	@echo "=====> Testing image..."
	@if [[ -z "`docker image ls $(IMAGE) | grep "\s${PUSH_VER}\s"`" ]]; \
		then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER) ]"; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing extensions..."
	@modules="`docker container run --rm $(IMAGE):$(PUSH_VER) php -m`"; \
	for ext in $(EXTENSIONS) $(EXT_EXTRA_CHECK); do \
	if [[ "$${modules}" != *"$${ext}"* ]]; \
		then echo "FAIL [module $${ext}]"; exit 1; fi; done
	@echo 'OK'

	@echo "=====> Testing composer..."
	@if [[ -z `docker container run --rm $(IMAGE):$(PUSH_VER) composer --version 2> /dev/null \
			| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing dev image..."
	@if [[ -z "`docker image ls $(IMAGE) | grep "\s${PUSH_VER}-dev\s"`" ]]; \
		then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER)-dev ]"; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing dev extensions..."
	@modules="`docker container run --rm $(IMAGE):$(PUSH_VER)-dev php -m`"; \
	for ext in $(EXTENSIONS) $(EXT_EXTRA_CHECK) xdebug; do \
	if [[ "$${modules}" != *"$${ext}"* ]]; \
		then echo "FAIL [module $${ext}]"; exit 1; fi; done
	@echo 'OK'

	@echo "=====> Testing dev composer..."
	@if [[ -z `docker container run --rm $(IMAGE):$(PUSH_VER)-dev composer --version 2> /dev/null \
			| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; exit 1; fi
	@echo 'OK'

push:
	@docker image push $(IMAGE):$(PUSH_VER)
	@docker image push $(IMAGE):$(PUSH_VER)-dev
