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
	poetry run isort task_manager/

black: isort
	poetry run black task_manager/

lint: isort black
	poetry run flake8 --config ./.flake8 task_manager/

# Run tests
test:
	poetry run pytest -vv --cov ./task_manager/ --cov-report term-missing:skip-covered

# Start & deploy project
start:
	poetry run ./manage.py runserver 0.0.0.0:8000

migrate:
	poetry run ./manage.py migrate

deploy:
	git push dokku main

# System commands for Makefile
MAKEFLAGS += --no-print-directory

.PHONY: requirements install isort black lint test start migrate deploy
