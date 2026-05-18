# ============================================================
#  MAKEFILE - Inception (Proyecto 42)
#  Diseñado para ejecutarse en una VM limpia (sin Docker).
#  Solo hace falta ejecutar "make" y todo se despliega solo.
# ============================================================

DATA_DIR	= /home/$(USER)/data
COMPOSE		= docker compose -f srcs/docker-compose.yml
DOMAIN		= acarranz.42.fr

# ────────────────────────────────────────────────────────────
# all: Punto de entrada único.
#   1. Instala Docker si no está (primera vez en VM limpia).
#   2. Añade el dominio a /etc/hosts si no existe ya.
#   3. Crea los directorios para los volúmenes persistentes.
#   4. Levanta los tres contenedores.
#
#   "sg docker" activa el grupo docker en la sesión actual
#   sin necesidad de cerrar sesión tras instalar Docker.
# ────────────────────────────────────────────────────────────
all:
	@if ! command -v docker > /dev/null 2>&1; then \
		echo "Docker no encontrado. Instalando..."; \
		sudo apt-get update -y; \
		sudo apt-get install -y ca-certificates curl gnupg; \
		sudo install -m 0755 -d /etc/apt/keyrings; \
		curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
			| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
		sudo chmod a+r /etc/apt/keyrings/docker.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" \
			| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
		sudo apt-get update -y; \
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
			docker-buildx-plugin docker-compose-plugin; \
		sudo usermod -aG docker $(USER); \
		echo "Docker instalado correctamente."; \
	fi
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "Añadiendo $(DOMAIN) a /etc/hosts..."; \
		echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
	fi
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	sg docker -c "$(COMPOSE) up -d --build"

# ────────────────────────────────────────────────────────────
# down: Para y elimina los contenedores (sin borrar datos).
# ────────────────────────────────────────────────────────────
down:
	sg docker -c "$(COMPOSE) down"

# ────────────────────────────────────────────────────────────
# re: Para todo y reconstruye desde cero.
#     Útil tras modificar Dockerfiles o scripts.
# ────────────────────────────────────────────────────────────
re: down all

# ────────────────────────────────────────────────────────────
# clean: Elimina contenedores, imágenes y datos en disco.
#        ⚠️  Borra la base de datos y archivos de WordPress.
# ────────────────────────────────────────────────────────────
clean: down
	sg docker -c "docker system prune -af"
	sudo rm -rf $(DATA_DIR)

fclean: clean

.PHONY: all down re clean fclean
