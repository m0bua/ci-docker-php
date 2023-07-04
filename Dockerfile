ARG IMAGE
FROM ${IMAGE}

RUN DISTRO="$(cat /etc/os-release | grep -E ^ID= | cut -d = -f 2)"; \
  if [ "${DISTRO}" = "debian" ] || [ "${DISTRO}" = "ubuntu" ]; then \
    DEBIAN_FRONTEND=noninteractive apt-get update -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y; \
    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y curl ssh-client git zip unzip sudo bash; \
  fi; \
  if [ "${DISTRO}" = "alpine" ]; then \
    packages="curl openssh git zip unzip zlib zlib-dev bash sudo npm"; \
    packages="${packages} automake make alpine-sdk nasm autoconf build-base shadow gcc musl-dev libtool pkgconf"; \
    packages="${packages} file tiff jpeg libpng libpng-dev libwebp libwebp-dev libjpeg-turbo libjpeg-turbo-dev"; \
    apk update; apk upgrade; apk add ${packages}; rm /var/cache/apk/*; \
  fi

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1
RUN list="bcmath bz2 calendar exif intl gd imagick ldap memcached xsl zip OPcache mcrypt"; \
    list="${list} mysqli pdo_mysql pdo_pgsql pgsql redis soap sockets pcntl mongodb"; \
    supported=$(curl -s https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/data/supported-extensions); \
    php=$(php -v | head -n1 | cut -d" " -f2 | cut -f1-2 -d"."); install=""; \
    for ext in $list; do \
      if [ ! -z "`echo "$supported" | grep -i "$ext" | grep "$php"`" ]; then install="$install $ext"; \
    fi; done; install-php-extensions "$install"; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
