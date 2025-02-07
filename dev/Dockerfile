ARG IMAGE
FROM ${IMAGE:-fpm-latest}

RUN php=$(php -v | head -n1 | cut -d" " -f2 | cut -f1-2 -d"."); install=""; \
    supported=$(curl -s https://raw.githubusercontent.com/mlocati/docker-php-extension-installer/master/data/supported-extensions); \
    [ ! -z "`echo "$supported" | grep -i xdebug | grep "$php"`" ] && install-php-extensions xdebug
