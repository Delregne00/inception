# ============================================================
#  DOCKERFILE - MariaDB
# ============================================================

FROM debian:bullseye

RUN apt-get update && apt-get install -y \
    mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Copiamos nuestra configuración personalizada.
# Sobreescribe el bind-address para que MariaDB acepte
# conexiones desde la red Docker (no solo localhost).
COPY conf/mariadb.conf /etc/mysql/mariadb.conf.d/99-custom.cnf

RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

# Script de inicialización: crea la BD y el usuario al primer arranque.
COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

# Puerto estándar de MySQL/MariaDB.
# Solo accesible desde la red interna Docker, no desde el exterior.
EXPOSE 3306

# setup.sh configura la BD y al final hace "exec $@" para
# ceder el control a CMD (mysqld), que se convierte en PID 1.
ENTRYPOINT ["/usr/local/bin/setup.sh"]
CMD ["mysqld"]
