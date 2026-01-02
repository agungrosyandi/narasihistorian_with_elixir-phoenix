.PHONY: docker-up docker-down docker-restart docker-logs
.PHONY: setup deps compile test format check
.PHONY: server iex routes db-setup db-migrate db-rollback db-reset db-seed
.PHONY: clean lint credo dialyzer

# Docker compose base command

DOCKER_COMPOSE = docker compose -f docker/docker-compose.yml -f docker/docker-compose.override.yml --env-file .env


## Docker commands

docker-up: ## Start Docker containers
	$(DOCKER_COMPOSE) up -d

docker-down: ## Stop Docker containers
	$(DOCKER_COMPOSE) down

docker-restart: ## Restart Docker containers
	$(DOCKER_COMPOSE) restart

docker-logs: ## Show Docker logs
	$(DOCKER_COMPOSE) logs -f

docker-exec: ## Execute command in app container (usage: make docker-exec CMD="mix ecto.migrate")
	$(DOCKER_COMPOSE) exec app $(CMD)

docker-shell: ## Open shell in app container
	$(DOCKER_COMPOSE) exec app sh

docker-rebuild: ## Rebuild and restart containers
	$(DOCKER_COMPOSE) up -d --build
