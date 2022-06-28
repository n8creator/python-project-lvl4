# Dev shortcuts
lint:
	poetry run flake8 task_manager

requirements:
	poetry export --without-hashes --format=requirements.txt > requirements.txt

check: lint # Check project before commit to git
	poetry run ./manage.py check


# Django shortcuts
run:
	poetry run ./manage.py runserver

messsages:
	poetry run ./manage.py makemessages --all
	poetry run ./manage.py compilemessages

.PHONY: lint requirements