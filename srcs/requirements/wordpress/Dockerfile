FROM debian:bullseye

# 1. Instalamos PHP-FPM y herramientas necesarias
RUN apt-get update && apt-get install -y \
    php7.4-fpm \
    php7.4-mysql \
    mariadb-client \
    curl && \
    rm -rf /var/lib/apt/lists/*

# 2. El TRUCO del puerto 9000:
# Por defecto PHP escucha en un archivo (.sock). 
# Lo cambiamos para que escuche en el puerto 9000 y Nginx pueda encontrarlo.
RUN sed -i 's/listen = \/run\/php\/php7.4-fpm.sock/listen = 9000/' \
    /etc/php/7.4/fpm/pool.d/www.conf

# 3. Instalamos el WP-CLI (La herramienta para configurar WP por comandos)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# 4. Preparamos carpetas y el script
RUN mkdir -p /var/www/html /run/php
COPY tools/setup.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup.sh

# 5. Directorio de trabajo (donde vivirá la web)
WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]

# Lanzamos PHP-FPM en primer plano (-F)
CMD ["/usr/sbin/php-fpm7.4", "-F"]