# Define Docker Compose shortcut
COMPOSE=docker compose

# Build only the app service
build:
	$(COMPOSE) build app

# Build and start both containers
up:
	$(COMPOSE) up --build

# Stop and remove containers, networks, and volumes
down:
	$(COMPOSE) down -v

# Clean everything (remove output and reset)
clean: down
	rm -rf out && mkdir -p out

# Do a full reset and start fresh
all: clean up
