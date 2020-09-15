# Docker PHP images
[![Build Status](https://travis-ci.org/m0bua/docker-php.svg?branch=master)](https://travis-ci.org/m0bua/docker-php)
[![Docker Pulls](https://img.shields.io/docker/pulls/m0bua/php.svg)](https://hub.docker.com/r/m0bua/php/)

Docker images built on top of the [official PHP images](https://hub.docker.com/_/php) with the addition of some common and useful extensions.

This project is based on [Chialab's source](https://github.com/Chialab/docker-php).

PHP extensions installed with [mlocati/docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer).

[Composer](https://getcomposer.org/) is installed globally in all images. Please, refer to their documentation for usage hints.

[Prestissimo (composer plugin)](https://github.com/hirak/prestissimo) is installed globally in all images. Plugin that downloads packages in parallel to speed up the installation process of Composer packages.

An automated build is set up, so they should be always up-to-date with the Dockerfiles in the [GitHub repository](https://github.com/m0bua/docker-php).

You can find these images on the [Docker Hub](https://hub.docker.com/r/m0bua/php).

## License
Docker PHP Images is released under the [MIT](https://github.com/m0bua/docker-php/blob/master/LICENSE) license.
