ARG IMAGE
FROM ${IMAGE:-fpm-latest}

RUN packages="curl openssh git zip unzip zlib zlib-dev bash sudo"; \
    packages="${packages} automake make alpine-sdk nasm autoconf build-base gcc musl-dev libtool pkgconf"; \
    packages="${packages} file tiff jpeg libpng libpng-dev libwebp libwebp-dev libjpeg-turbo libjpeg-turbo-dev pngquant"; \
    apk update --no-cache; apk upgrade --no-cache; apk add --no-cache ${packages};

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/
ENV PATH=$PATH:/root/composer/vendor/bin COMPOSER_ALLOW_SUPERUSER=1
RUN list="bcmath bz2 calendar exif intl gd imagick ldap xsl zip mcrypt geoip"; \
    list="${list} mysql mysqli pdo_mysql pdo_pgsql mongodb redis OPcache memcached soap sockets pcntl "; \
    php=$(php -v | head -n1 | cut -d" " -f2 | cut -f1-2 -d"."); install=""; \
    supported=$(curl -s https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/data/supported-extensions); \
    for ext in $list; do \
      [ ! -z "`echo "$supported" | grep -i "$ext" | grep "$php"`" ] && install="$install $ext"; \
    done; install-php-extensions "$install"; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    && ln -s $(composer config --global home) /root/composer
