ARG ALPINE_VERSION=3.21
FROM alpine:${ALPINE_VERSION}
LABEL Maintainer="Akurosia Kamo"
LABEL Description="Lightweight container with Nginx 1.26 & PHP 8.4 based on Alpine Linux."
ENV PYTHONUNBUFFERED=1

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  imagemagick \
  php84 \
  php84-ctype \
  php84-curl \
  php84-dom \
  php84-fileinfo \
  php84-fpm \
  php84-gd \
  php84-intl \
  php84-mbstring \
  php84-mysqli \
  php84-pdo_mysql \
  php84-opcache \
  php84-openssl \
  php84-phar \
  php84-session \
  php84-tokenizer \
  php84-xml \
  php84-xmlreader \
  php84-xmlwriter \
  supervisor

RUN apk add --update --no-cache python3 && ln -sf python3 /usr/bin/python
RUN python3 -m ensurepip
RUN pip3 install --no-cache --upgrade pip setuptools img2webp build twine PyGithub pandas openpyxl selenium pyaml requests IPy discord.py bs4 colorama pyopenssl tqdm unidecode image urllib3 flask pyinstaller Pillow construct pylint dictdiffer demjson3 gevent connexion flask_cors watchdog pysimplegui sty GitPython netifaces PyYAML requests natsort openpyxl python-dateutil gitpython fflogsapi PySimpleGUI dictdiffer Pyaml
RUN pip3 install --extra-index-url https://pip.akurosia.de/simple ffxiv_aku -U --break-system-packages
RUN ln -s /usr/bin/php84 /usr/bin/php

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
ENV PHP_INI_DIR /etc/php84
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
