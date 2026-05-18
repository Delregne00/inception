#!/bin/bash

# ============================================================
#  SETUP.SH - WordPress
#  Descarga, configura e instala WordPress en el primer arranque.
# ============================================================

# ── Leer contraseñas desde Docker Secrets ────────────────────
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

# ── Esperar a que MariaDB esté lista ─────────────────────────
# Docker starts los contenedores en orden (depends_on) pero
# no garantiza que MariaDB esté lista para aceptar conexiones.
echo "Esperando a MariaDB..."
until mysqladmin ping -h mariadb -u"${MYSQL_USER}" -p"${MYSQL_PASSWORD}" --silent 2>/dev/null; do
    sleep 2
done
echo "MariaDB lista."

# ── Instalar WordPress solo si no está ya instalado ──────────
# wp-config.php es el indicador de que WP ya fue configurado.
# Esto evita reinstalar en cada reinicio del contenedor.
if [ ! -f /var/www/html/wp-config.php ]; then

    echo "Instalando WordPress..."

    # 1. Descargar los archivos core de WordPress
    wp core download --allow-root

    # 2. Crear wp-config.php con la conexión a la BD
    #    dbhost=mariadb: Docker resuelve el nombre del servicio a su IP
    wp config create \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb \
        --allow-root

    # 3. Instalar WordPress (crea las tablas en la BD)
    #    La URL usa el dominio del .env (ej: acarranz.42.fr)
    wp core install \
        --url="https://${DOMAIN_NAME}" \
        --title="Inception" \
        --admin_user="${WP_ADMIN}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}" \
        --skip-email \
        --allow-root

    # 4. Crear segundo usuario con rol subscriber (lector)
    #    El subject exige que haya al menos 2 usuarios,
    #    y el segundo NO puede tener rol de administrador.
    wp user create \
        "${WP_USER}" \
        "${WP_USER_EMAIL}" \
        --user_pass="${WP_USER_PASSWORD}" \
        --role=subscriber \
        --allow-root

    echo "WordPress instalado correctamente."
else
    echo "WordPress ya estaba instalado. Saltando instalación."
fi

# ── Ceder el control a CMD (php-fpm) ─────────────────────────
exec "$@"
