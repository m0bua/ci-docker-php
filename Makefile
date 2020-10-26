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

ORIG_ERROR := $(shell docker pull $(ORIG_IMG):$(VERSION) >/dev/null 2>&1)
ORIG_DATE := $(shell [[ -z "$(ORIG_ERROR)" ]] && docker inspect -f '{{ .Created }}' $(ORIG_IMG):$(VERSION) 2>/dev/null)
CONT_ERROR := $(shell docker pull $(IMAGE):$(PUSH_VER) >/dev/null 2>&1)
CONT_DATE := $(shell [[ -z "$(CONT_ERROR)" ]] && docker inspect -f '{{ .Created }}' $(IMAGE):$(PUSH_VER) 2>/dev/null)
NEEDS_UPDATE := $(shell [[ -z "$(CONT_DATE)" || `date -d "$(ORIG_DATE)" +%s` -gt `date -d "$(CONT_DATE)" +%s` ]] && echo "true")
COMPARE := Origin image: $(ORIG_IMG):$(VERSION), ($(ORIG_DATE)), builded one: $(IMAGE):$(PUSH_VER), ($(CONT_DATE)).

ifeq "$(NEEDS_UPDATE)" "true"

build:
	@echo "=====> Building image... $(COMPARE)"
	@ext="$(EXTENSIONS)"; docker image build --quiet -t build-$(IMAGE):$(PUSH_VER) . \
		--build-arg EXTENSIONS="$${ext,,}" \
		--build-arg IMAGE=$(ORIG_IMG) \
		--build-arg VERSION=$(VERSION);
	@docker image build --quiet -t build-$(IMAGE):$(PUSH_VER)-dev dev \
		--build-arg IMAGE=build-$(IMAGE) \
		--build-arg VERSION=$(PUSH_VER);

test:
	@echo "=====> Testing image... $(COMPARE)"
	@if [[ -z "`docker image ls build-$(IMAGE) | grep "\s${PUSH_VER}\s"`" ]]; \
		then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER) ]"; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing extensions..."
	@modules="`docker container run --rm build-$(IMAGE):$(PUSH_VER) php -m`"; \
	for ext in $(EXTENSIONS) $(EXT_EXTRA_CHECK); do \
	if [[ "$${modules}" != *"$${ext}"* ]]; \
		then echo "FAIL [module $${ext}]"; exit 1; fi; done
	@echo 'OK'

	@echo "=====> Testing composer..."
	@if [[ -z `docker container run --rm build-$(IMAGE):$(PUSH_VER) composer --version 2> /dev/null \
			| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing dev image... $(COMPARE)"
	@if [[ -z "`docker image ls build-$(IMAGE) | grep "\s${PUSH_VER}-dev\s"`" ]]; \
		then echo "FAIL [ Missing image $(IMAGE):$(PUSH_VER)-dev ]"; exit 1; fi
	@echo 'OK'

	@echo "=====> Testing dev extensions..."
	@modules="`docker container run --rm build-$(IMAGE):$(PUSH_VER)-dev php -m`"; \
	for ext in $(EXTENSIONS) $(EXT_EXTRA_CHECK) xdebug; do \
	if [[ "$${modules}" != *"$${ext}"* ]]; \
		then echo "FAIL [module $${ext}]"; exit 1; fi; done
	@echo 'OK'

	@echo "=====> Testing dev composer..."
	@if [[ -z `docker container run --rm build-$(IMAGE):$(PUSH_VER)-dev composer --version 2> /dev/null \
			| grep '^Composer version [0-9][0-9]*\.[0-9][0-9]*'` ]]; then \
		echo 'FAIL [Composer]'; exit 1; fi
	@echo 'OK'

push:
	@docker tag build-$(IMAGE):$(PUSH_VER) $(IMAGE):$(PUSH_VER)
	@docker image push $(IMAGE):$(PUSH_VER)
	@docker tag build-$(IMAGE):$(PUSH_VER)-dev $(IMAGE):$(PUSH_VER)-dev
	@docker image push $(IMAGE):$(PUSH_VER)-dev

else

build:
	@echo "=====> Nothing to build. $(COMPARE)"

test:
	@echo "=====> Nothing to test. $(COMPARE)"

push:
	@echo "=====> Nothing to push. $(COMPARE)"

endif
