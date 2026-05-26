DATA_DIR	= /root/data
DOMAIN		= acarranz.42.fr

all:
	@if ! command -v docker > /dev/null 2>&1; then \
		echo "Instalando Docker..."; \
		apt-get update -y; \
		apt-get install -y ca-certificates curl gnupg; \
		install -m 0755 -d /etc/apt/keyrings; \
		OS_ID=$$(. /etc/os-release && echo "$$ID"); \
		curl -fsSL https://download.docker.com/linux/$$OS_ID/gpg \
			| gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
		chmod a+r /etc/apt/keyrings/docker.gpg; \
		echo "deb [arch=$$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/$$OS_ID \
$$(. /etc/os-release && echo "$$VERSION_CODENAME") stable" \
			| tee /etc/apt/sources.list.d/docker.list > /dev/null; \
		apt-get update -y; \
		apt-get install -y docker-ce docker-ce-cli containerd.io \
			docker-buildx-plugin docker-compose-plugin; \
	fi
	@mkdir -p /etc/docker
	@echo '{"dns": ["8.8.8.8", "8.8.4.4"]}' | tee /etc/docker/daemon.json > /dev/null
	@systemctl enable docker 2>/dev/null || true
	@systemctl start docker 2>/dev/null || service docker start
	@mkdir -p secrets
	@if [ ! -f secrets/db_password.txt ]; then \
		echo "Db_Password42!" > secrets/db_password.txt; \
		echo "Db_Root_Password42!" > secrets/db_root_password.txt; \
		echo "Wp_Admin_Password42!" > secrets/credentials.txt; \
	fi
	@grep -q "^LOGIN=" srcs/.env && sed -i "s/^LOGIN=.*/LOGIN=root/" srcs/.env || echo "LOGIN=root" >> srcs/.env
	@if ! grep -q "$(DOMAIN)" /etc/hosts; then \
		echo "127.0.0.1 $(DOMAIN)" | tee -a /etc/hosts; \
	fi
	@mkdir -p $(DATA_DIR)/wordpress $(DATA_DIR)/mariadb
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

re: down all

clean: down
	docker system prune -af
	rm -rf $(DATA_DIR)

fclean: clean

.PHONY: all down re clean fclean
