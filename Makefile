.PHONY: \
	build-production build-staging build-development \
	up up-production up-staging up-development \
	down

APP_IMAGE ?= forerunner-app

build-production:
	docker build --target production --tag $(APP_IMAGE):production .

build-staging:
	docker build --target staging --tag $(APP_IMAGE):staging .

build-development:
	docker build --target development --tag $(APP_IMAGE):development .

up: up-development

up-production:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=production docker compose up --build

up-staging:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=staging docker compose up --build

up-development:
	APP_IMAGE=$(APP_IMAGE) APP_ENV=development docker compose up --build

down:
	docker compose down -v