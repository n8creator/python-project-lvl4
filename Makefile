DIRS = task_manager/

# Setup
install:
	@poetry install

# Lint
isort:
	poetry run isort $(DIRS)

black: isort
	@poetry run black $(DIRS)

format: isort black

lint:
	@poetry run flake8 --config ./.flake8 $(DIRS)

# Run tests
test:
#   poetry run pytest -vv $(DIRS) --cov --cov-report term-missing:skip-covered
	poetry run pytest -vv $(DIRS) --cov

coverage_xml:
	poetry run coverage xml

# Start & deploy project
start:
	poetry run ./manage.py runserver 0.0.0.0:8000

migrate:
	poetry run ./manage.py migrate

# System commands for Makefile
MAKEFLAGS += --no-print-directory

.PHONY: install isort black format lint test coverage_xml start migrate
