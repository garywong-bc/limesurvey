# Get current directory, without special '.' character
VOLUME=$(subst .,,$(shell basename $(PWD)))

APP_DIR=$(PWD)
TS=$(shell date +%Y%m%d%H%M%S)

develop: clean build run

clean:
	docker compose rm -vf
	docker compose down -v 

build:
	docker compose build 

build-nocache:
	docker compose build --no-cache

# http://localhost:8080/index.php/admin/authentication/sa/login
run: 
	docker compose up -d
	docker compose logs -f

reset: clean
#	rm -rf db/data/*
	rm -rf volumes/config/*
	rm -rf volumes/plugins/*
	rm -rf volumes/upload/*

