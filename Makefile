lint:
	poetry run flake8 task_manager

requirements:
	poetry export --without-hashes --format=requirements.txt > requirements.txt

.PHONY: lint requirements