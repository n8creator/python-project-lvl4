# Use an official Python runtime based on Debian 10 "buster" as a parent image.
FROM python:3.11.0-slim-buster

# Add user that will be used in the container.
RUN useradd django_user

# Port used by this container to serve HTTP.
EXPOSE 5000

# Set environment variables.
# 1. Force Python stdout and stderr streams to be unbuffered.
# 2. Set PORT variable that is used by Gunicorn. This should match "EXPOSE"
#    command.
ENV PYTHONUNBUFFERED=1 \
    PORT=5000\
    # Poetry Env Variables
    POETRY_VERSION=1.7 \
    POETRY_VIRTUALENVS_CREATE=false \
    POETRY_CACHE_DIR="/var/cache/pypoetry"

# Install system packages required by Django.
RUN apt-get update --yes --quiet && apt-get install --yes --quiet --no-install-recommends \
    build-essential \
    libpq-dev \
    libmariadbclient-dev \
    libjpeg62-turbo-dev \
    zlib1g-dev \
    libwebp-dev \
    # Custom packages needed for debug on production server
    # neovim - required to navigate through files within container
    # postgresql-client - required to run './manage dbshell' command
    postgresql-client neovim tree curl \
    # Cleaning cache:
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install the project requirements via Poetry.
COPY poetry.lock pyproject.toml /
RUN pip3 install "poetry==$POETRY_VERSION" && poetry --version
RUN poetry install --without test,code-quality

# Use /app folder as a directory where the source code is stored.
WORKDIR /app

# Set this directory to be owned by the "django_user" user.
RUN chown django_user:django_user /app

# Copy the source code of the project into the container.
COPY --chown=django_user:django_user . .

# Use user "django_user" to run the build commands below and the server itself.
USER django_user

# Collect static files.
RUN python manage.py collectstatic --noinput --clear

# Runtime command that executes when "docker run" is called, it does the
# following:
#   1. Migrate the database.
#   2. Start the application server.
# WARNING:
#   Migrating database at the same time as starting the server IS NOT THE BEST
#   PRACTICE. The database should be migrated manually or using the release
#   phase facilities of your hosting platform.
CMD set -xe; python manage.py migrate --noinput; gunicorn task_manager.wsgi:application
