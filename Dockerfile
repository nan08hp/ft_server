FROM debian:buster

RUN set -ex; \
	apt-get update && apt-get install -y \
	nginx \
	mariadb-server \
	supervisor \
	openssl	\
	curl \
	vim \
	php \
	php-fpm \
	php-curl \
	php-mbstring \
	php-mysql \
	php-xml \
	php-zip \
	imagemagick \
	php-imagick \
	&& rm -rf /var/lib/apt/list/*

WORKDIR /var/www/html

# Setup mysql
RUN set -ex; \
	service mysql start \
	&& mysql -e "CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin'; " \
	&& mysql -e "CREATE DATABASE IF NOT EXISTS wordpress; " \
	&& mysql -e "GRANT ALL ON wordpress.* TO 'admin'@'localhost';"

# Setup WordPress
RUN set -ex; \
	curl -OL https://ja.wordpress.org/latest-ja.tar.gz \
	&& tar -xzvf latest-ja.tar.gz -C /var/www/html/ \
	&& rm -rf latest-ja.tar.gz
COPY srcs/wordpress/wp-config.php /var/www/html/wordpress

# Setup phpmyadmin
RUN set -ex; \
	curl -OL https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.tar.gz \
	&& tar -xzvf phpMyAdmin-5.1.1-all-languages.tar.gz -C /var/www/html/ \
	&& mv phpMyAdmin-5.1.1-all-languages phpMyAdmin \
	&& rm -rf phpMyAdmin-5.1.1-all-languages.tar.gz \
	&& chmod 777 /var/www/html/wordpress

# Setup nginx
COPY srcs/nginx/default.tmpl /etc/nginx/sites-available/

# Setup ssl setting
RUN set -ex; \
	mkdir /etc/nginx/ssl \
	&& openssl genrsa -out /etc/nginx/ssl/server.key 2048 \
	&& openssl req -new -key /etc/nginx/ssl/server.key -out /etc/nginx/ssl/server.csr -subj '/C=JP/ST=Tokyo/L=Tokyo/O=42Tokyo/OU=42Tokyo/CN=localhost' \
	&& openssl x509 -days 3650 -req -signkey /etc/nginx/ssl/server.key -in /etc/nginx/ssl/server.csr -out /etc/nginx/ssl/server.crt

# Setup supervisord
COPY srcs/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Install entrykit
RUN set -ex; \
	curl -OL https://github.com/progrium/entrykit/releases/download/v0.4.0/entrykit_0.4.0_Linux_x86_64.tgz \
	&& tar -xvzf entrykit_0.4.0_Linux_x86_64.tgz -C /bin \
	&& rm entrykit_0.4.0_Linux_x86_64.tgz \
	&& chmod +x /bin/entrykit \
	&& entrykit --symlink

# For Setup php-fpm
RUN mkdir -p /var/run/php

expose 80 443
ENTRYPOINT ["render", "/etc/nginx/sites-available/default", "--",  "/usr/bin/supervisord"]
#ENTRYPOINT ["render", "", "--",  "/usr/bin/supervisord"]
#ENTRYPOINT ["/usr/bin/supervisord"]
