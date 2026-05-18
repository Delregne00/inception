#!/bin/bash

# ============================================================
#  SETUP.SH - MariaDB
#  Inicializa la base de datos al primer arranque del contenedor.
# ============================================================

# ── Leer contraseñas desde Docker Secrets ────────────────────
# Los secrets se montan como archivos en /run/secrets/.
# Así las contraseñas NUNCA aparecen en variables de entorno
# ni en logs del contenedor.
MYSQL_PASSWORD=$(cat /run/secrets/db_password)
MYSQL_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# ── Arrancar MariaDB temporalmente para configurarla ─────────
# --skip-networking: solo acepta conexiones locales durante el setup.
# --user=mysql: ejecuta el proceso como usuario mysql (no root).
# El & lo manda al background para que el script pueda continuar.
mysqld --user=mysql --skip-networking &
MARIADB_PID=$!

# ── Esperar a que MariaDB esté lista ─────────────────────────
# mysqladmin ping devuelve 0 cuando el servidor responde.
until mysqladmin ping --silent 2>/dev/null; do
    sleep 1
done

# ── Crear la base de datos, el usuario y configurar root ─────
mysql -e "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;"

# '%' significa que el usuario puede conectar desde cualquier
# host (necesario para que WordPress conecte desde otro contenedor).
mysql -e "CREATE USER IF NOT EXISTS \`${MYSQL_USER}\`@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO \`${MYSQL_USER}\`@'%';"

# Cambiamos la contraseña de root por seguridad.
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
mysql -e "FLUSH PRIVILEGES;"

# ── Apagar la instancia temporal ─────────────────────────────
mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} shutdown
wait $MARIADB_PID

# ── Ceder el control a CMD (mysqld) ──────────────────────────
# exec reemplaza este script por mysqld, que se convierte en
# PID 1 del contenedor. Así Docker puede gestionarlo correctamente.
exec "$@"
