# ============================================================
#  MAKEFILE - Inception (Proyecto 42)
#  Diseñado para ejecutarse en una VM limpia (sin Docker).
#  Solo hace falta ejecutar "make" y todo se despliega solo.
# ============================================================

DATA_DIR	= /home/$(USER)/data
DOMAIN		= acarranz.42.fr

all:
	@if ! command -v docker > /dev/null 2>&1; then \
		echo "Instalando Docker..."; \
		sudo apt-get update -y; \
		sudo apt-get install -y ca-certificates curl gnupg; \
		sudo install -m 0755 -d /etc/apt/keyrings; \
		OS_ID=$$(. /etc/os-release && echo "$$ID"); \
		curl -fsSL https://download.docker.com/linux/$$OS_ID/gpg \
			| sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
		sudo chmod a+r /etc/apt/keyrings/docker.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$$OS_ID \
$$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" \
			| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; \
		sudo apt-get update -y; \
		sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
			docker-buildx-plugin docker-compose-plugin; \
		sudo groupadd -f docker; \
		sudo usermod -aG docker $(USER); \
	fi
	@sudo mkdir -p /etc/docker
	@echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' | sudo tee /etc/docker/daemon.json > /dev/null
	@sudo systemctl enable docker 2>/dev/null || true
	@sudo systemctl start docker 2>/dev/null || sudo service docker start
	@mkdir -p secrets
	@if [ ! -f secrets/db_password.txt ]; then \
		echo "Db_Password42!" > secrets/db_password.txt; \
		echo "Db_Root_Password42!" > secrets/db_root_password.txt; \
		echo "Wp_Admin_Password42!" > secrets/credentials.txt; \
	fi
	@grep -q "^LOGIN=" srcs/.env && sed -i "s/^LOGIN=.*/LOGIN=$(USER)/" srcs/.env || echo "LOGIN=$(USER)" >> srcs/.env
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN)" | sudo tee -a /etc/hosts; \
	fi
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	sudo -E docker compose -f srcs/docker-compose.yml up -d --build

down:
	sudo -E docker compose -f srcs/docker-compose.yml down

re: down all

clean: down
	sudo -E docker system prune -af
	sudo rm -rf $(DATA_DIR)

fclean: clean

.PHONY: all down re clean fclean