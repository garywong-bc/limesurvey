# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker compose rm -vf
	docker compose down -v 

build:
	docker compose build --build-arg DOCKER_REGISTRY=docker.io/library

build-nocache:
	docker compose build --build-arg DOCKER_REGISTRY=docker.io/library --no-cache

# http://localhost/index.php/admin/authentication/sa/login
run: 
	docker compose up -d
	docker compose logs -f

reset: clean
	rm -rf volumes/db/data/*
	rm -rf volumes/config/*
	rm -rf volumes/plugins/*
	rm -rf volumes/upload/*

db-shell:
	docker compose exec mysql /bin/bash

# need mysql_native_password setting or plugin
# db-term:
# 	docker compose exec mysql /bin/bash -c 'mysql -u $${LIMESURVEY_ADMIN_USER} -p$${LIMESURVEY_ADMIN_PASSWORD} mysql'

# To focus on LimeSurvey tables: \u limesurvey
db-root-term:
	docker compose exec mysql /bin/bash -c 'mysql -u root -D mysql -p$${MYSQL_ROOT_PASSWORD}'

# Login as default_user 
app-shell:
	docker compose exec app /bin/bash

app-root-shell:
	docker compose exec -u root app /bin/bash