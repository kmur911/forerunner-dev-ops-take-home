.PHONY: \
	build-prod build-staging build-dev \
	up up-prod up-staging up-dev \
	down

APP_IMAGE ?= forerunner-app

build-prod:
	docker build --target production --tag $(APP_IMAGE):production .

build-staging:
	docker build --target staging --tag $(APP_IMAGE):staging .

build-dev:
	docker build --target development --tag $(APP_IMAGE):development .

up: up-dev

up-prod:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=production docker compose up --build

up-staging:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=staging docker compose up --build

up-dev:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=development docker compose up --build

down:
	docker compose down -v