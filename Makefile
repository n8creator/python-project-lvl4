# Export poetry dependencies into requirements.txt file
requirements:
	@poetry export --without-hashes --format requirements.txt \
		--output ./requirements.txt
	@poetry export --without-hashes --format requirements.txt \
		--output ./requirements.dev.txt --with test --with code-quality --with utils

# Install project
install:
	@poetry install

# Lint project
isort:
	@poetry run isort task_manager

black:
	@poetry run black task_manager

lint: black
	@poetry run flake8 task_manager

# Run tests
test:
	@poetry run ./manage.py test

# Start & deploy project
start:
	@poetry run ./manage.py runserver 0.0.0.0:8000

migrate:
	poetry run ./manage.py migrate

deploy:
	git push dokku main

# System commands for Makefile
MAKEFLAGS += --no-print-directory

.PHONY: requirements install isort black lint test start migrate deploy