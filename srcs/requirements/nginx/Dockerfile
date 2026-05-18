# ============================================================
#  DOCKERFILE - Nginx
#  Servidor web con SSL/TLS que hace de "puerta de entrada"
# ============================================================

# Usamos Debian Bullseye como base (requisito de 42)
FROM debian:bullseye

# ────────────────────────────────────────────────────────────
# Instalamos Nginx.
# - nginx: el servidor web/proxy inverso
# Limpiamos caché de apt para reducir tamaño de imagen.
# ────────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    nginx \
    openssl && \
    rm -rf /var/lib/apt/lists/*

# ────────────────────────────────────────────────────────────
# Copiamos la configuración de Nginx al lugar correcto.
# "default.conf" define cómo Nginx maneja las peticiones:
# SSL, redirección a PHP-FPM (WordPress), etc.
# ────────────────────────────────────────────────────────────
COPY conf/default.conf /etc/nginx/sites-available/default

# ────────────────────────────────────────────────────────────
# Copiamos el certificado y la clave SSL pre-generados.
# En producción se usaría Let's Encrypt, pero para el proyecto
# usamos certificados auto-firmados (suficiente para 42).
# ────────────────────────────────────────────────────────────
RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=ES/ST=Barcelona/L=Barcelona/O=42/CN=acarranz.42.fr"

# ────────────────────────────────────────────────────────────
# Exponemos el puerto 443 (HTTPS).
# El proyecto exige HTTPS, el puerto 80 (HTTP) NO se usa.
# Este puerto SÍ se mapea al host en docker-compose.yml.
# ────────────────────────────────────────────────────────────
EXPOSE 443

# ────────────────────────────────────────────────────────────
# Lanzamos Nginx en primer plano.
# "daemon off" es obligatorio en Docker: si Nginx se va al
# background, el contenedor cree que el proceso terminó y se cierra.
# ────────────────────────────────────────────────────────────
CMD ["nginx", "-g", "daemon off;"]
