# Taken from https://github.com/engelsystem/engelsystem/blob/main/docker/Dockerfile

FROM alpine as source
RUN apk add git && \
    git clone https://github.com/engelsystem/engelsystem.git

# Composer install
FROM composer:latest AS composer
COPY --from=source /engelsystem /app/
RUN composer --no-ansi install --no-dev --ignore-platform-reqs
RUN composer --no-ansi dump-autoload --optimize

# Generate .mo files
FROM alpine AS translation
RUN apk add gettext
COPY --from=source /engelsystem/resources/lang/ /data
RUN find /data -type f -name '*.po' -exec sh -c 'msgfmt "${1%.*}.po" -o"${1%.*}.mo"' shell {} \;

# Build the themes
FROM node:20-alpine AS themes
WORKDIR /app
COPY --from=source /engelsystem/.babelrc /engelsystem/.browserslistrc /engelsystem/package.json /engelsystem/webpack.config.js /engelsystem/yarn.lock /app/
RUN yarn --frozen-lockfile
COPY --from=source /engelsystem/resources/assets/ /app/resources/assets
RUN yarn build

# Generate application structure
FROM alpine AS data
COPY --from=source /engelsystem/.babelrc /engelsystem/.browserslistrc /engelsystem/composer.json /engelsystem/LICENSE /engelsystem/package.json /engelsystem/README.md /engelsystem/webpack.config.js /engelsystem/yarn.lock /app/
COPY --from=source /engelsystem/bin/ /app/bin
COPY --from=source /engelsystem/config/ /app/config
COPY --from=source /engelsystem/db/ /app/db
COPY --from=source /engelsystem/includes/ /app/includes
COPY --from=source /engelsystem/public/ /app/public
COPY --from=source /engelsystem/resources/api /app/resources/api
COPY --from=source /engelsystem/resources/views /app/resources/views
COPY --from=source /engelsystem/src/ /app/src
COPY --from=source /engelsystem/storage/ /app/storage

COPY --from=translation /data/ /app/resources/lang
COPY --from=composer /app/vendor/ /app/vendor
COPY --from=composer /app/composer.lock /app/
COPY --from=themes /app/public/assets /app/public/assets/

RUN find /app/storage/ -type f -not -name VERSION -exec rm {} \;

# Build the PHP/Nginx container
FROM php:8.3-fpm-alpine
WORKDIR /var/www/engelsystem
RUN apk add --no-cache icu-dev nginx && \
    docker-php-ext-install intl pdo_mysql

COPY --from=data /app/ /var/www/engelsystem
RUN chown -R www-data:www-data /var/www/engelsystem/storage/ && \
    rm -r /var/www/html

ARG VERSION
RUN if [[ ! -f /var/www/engelsystem/storage/app/VERSION ]] && [[ ! -z "${VERSION}" ]]; then \
echo -n "${VERSION}" > /var/www/engelsystem/storage/app/VERSION; fi

ENV TRUSTED_PROXIES 10.0.0.0/8,::ffff:10.0.0.0/8,\
                    127.0.0.0/8,::ffff:127.0.0.0/8,\
                    172.16.0.0/12,::ffff:172.16.0.0/12,\
                    192.168.0.0/16,::ffff:192.168.0.0/16,\
                    ::1/128,fc00::/7,fec0::/10

ENTRYPOINT [ "php-fpm" ]