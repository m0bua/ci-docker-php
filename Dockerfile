ARG IMAGE
ARG VERSION
FROM ${IMAGE}:${VERSION}

ARG EXTENSIONS

ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

RUN DISTRO="$(cat /etc/os-release | grep -E ^ID= | cut -d = -f 2)"; \
  if [ "${DISTRO}" = "ubuntu" ]; then \
    DEBIAN_FRONTEND=noninteractive apt-get update -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y curl git zip unzip; \
  fi; \
  if [ "${DISTRO}" = "alpine" ]; then \
    apk update; apk upgrade; apk add curl git zip unzip bash; rm /var/cache/apk/*; \
  fi

RUN install-php-extensions "$EXTENSIONS"

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
  ln -s $(composer config --global home) /root/composer && composer global require hirak/prestissimo
