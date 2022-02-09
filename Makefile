# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker compose down -v  --remove-orphans

build:
	docker compose build --build-arg DOCKER_REGISTRY=docker.io/library

build-nocache:
	docker compose build --build-arg DOCKER_REGISTRY=docker.io/library --no-cache

# http://localhost/admin/authentication/sa/login
run: 
	docker compose up -d
	docker compose logs -f

reset: clean
	docker volume prune

db-shell:
	docker compose exec mysql /bin/bash

db-term:
	docker compose exec mysql /bin/bash -c 'mysql -u $${MYSQL_USER} -p$${MYSQL_PASSWORD}'

# To focus on LimeSurvey tables: \u limesurvey
db-root-term:
	docker compose exec mysql /bin/bash -c 'mysql -u root -D mysql -p$${MYSQL_ROOT_PASSWORD}'

# Login as default_user 
app-shell:
	docker compose exec app /bin/bash

app-root-shell:
	docker compose exec -u root app /bin/bash