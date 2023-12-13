# Deploy Django project to Dokku (Short Guide)

## 1. Check if Dokku installed on remote machine

```sh
$ dokku -v
dokku version 0.30.8
```

## 2. Configure Dokku apps

Create new Dokku app:

```sh
$ dokku apps:create monet-web
-----> Creating monet-web...
-----> Creating new app virtual host file...
```

Check if PostgreSQL plugin installed and install if not:

```sh
# Check if PostgreSQL plugin installed
$ dokku plugin:list | grep postgres
  postgres             1.34.0 enabled    dokku postgres service plugin

# Install plugin
$ dokku plugin:install https://github.com/dokku/dokku-postgres.git
```

Create PostgreSQL instance from TimescaleDB database:

```sh
# Create DB instance from Timescale DB
$ dokku postgres:create monet-db --image 'timescale/timescaledb' --image-version 'latest-pg15';
```

List all PostgreSQL services:

```sh
$ dokku postgres:list
=====> Postgres services
monet-db
```

Link PostgreSQL to app and get `DATABASE_URL`:

```sh
$ dokku postgres:link monet-db monet-web
-----> Setting config vars
       DATABASE_URL:  postgres://postgres:b...@dokku-postgres-monet-db:5432/monet_db
-----> Restarting app monet-web
 !     App image (dokku/monet-web:latest) not found
```

Print out the env of `monet-web` Dokku app:

```sh
$ dokku config:show monet-web
=====> monet-web env vars
DATABASE_URL:  postgres://postgres:8...e@dokku-postgres-monet-db:5432/monet_db
```

## 3. Configure Env's

### 4.1. Configure other Env's

Enter following settings:

```sh
$ dokku config:set --no-restart monet-web SECRET_KEY='SECRET_KEY_HERE'
$ dokku config:set --no-restart monet-web SETTINGS_MODULE='task_manager.settings'
$ dokku config:set --no-restart monet-web DEBUG='False'
```

Call this command to check Env settings on server:

```sh
$ dokku config:show monet-web
```

## 4. Add custom domain and setup SSL

### 4.1. Add custom domain

Add custom domain:

```sh
$ dokku domains:add monet-web monet.n8creator.com
-----> Added monet.n8creator.com to monet-web
 !     Please run dokku letsencrypt:enable to add https support to the new domain
 !     No web listeners specified for monet-web
```

and check `domains:report`:

```sh
$ dokku domains:report monet-web
=====> monet-web domains information
       Domains app enabled:           true
       Domains app vhosts:            monet.n8creator.com
       Domains global enabled:        false
       Domains global vhosts:
```

### 4.2. Configure SSL script

Configure Let's encrypt SSL:

```sh
$ dokku letsencrypt:set --global email n8creator@pm.me
$ dokku letsencrypt:enable monet-web

# this would setup cron job to update letsencrypt certificate
$ dokku letsencrypt:cron-job --add
```

## 5. Configure Django project (on local machine)

### 5.1. Environment setup

Add `django-environ` dependency:

```sh
$ poetry add python-dotenv
```

Update Django settings `task_manager/settings.py` to use `python-dotenv` to read the env.

```python
import dj_database_url
from dotenv import load_dotenv

# Load ENV variables
load_dotenv()

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv("SECRET_KEY", "secret_key")

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv("DEBUG", "False")

ALLOWED_HOSTS = [
    "127.0.0.1",
    "localhost",
    "webserver",
    "monet.n8creator.com",
]
```

Run local server and check if app works:

```sh
$ ./manage.py migrate
$ ./manage.py runserver
```

Check on http://127.0.0.1:8000/ to make sure everything is working.

### 5.2. Serve static files

Install `whitenoise` to serve static files:

```sh
$ poetry add whitenoise
```

And update Django settings `task_manager/settings.py` file:

```python
import os

MIDDLEWARE = [
   'django.middleware.security.SecurityMiddleware',
   'whitenoise.middleware.WhiteNoiseMiddleware',
   # ...
]

STATIC_URL = 'static/'
STATIC_ROOT = os.path.join(BASE_DIR, 'static')

STATICFILES_STORAGE = "whitenoise.storage.CompressedManifestStaticFilesStorage"
```

### 5.3. Configure Postgres DB

Update `task_manager/settings.py` file:

```python
if DEBUG:
    # Use SQLite for local development
    DATABASES = {
        "default": {
            "ENGINE": "django.db.backends.sqlite3",
            "NAME": BASE_DIR / "db.sqlite3",
        }
    }
else:
    # Use PostgreSQL for production on Dokku server
    DATABASES = {
        "default": dj_database_url.config(
            default=os.environ.get("DATABASE_URL"),
            conn_max_age=600,
            conn_health_checks=True,
        ),
    }
```

Add `psycopg2-binary` to dependencies:

```sh
$ poetry add psycopg2-binary
```

### 5.4. Add `runtime.txt`

To specify a Python runtime, add a `runtime.txt` file to app’s root directory that declares the exact version number to use:

```txt
python-3.10.0
```

### 6.6. Add Procfile

Procfile contains entry command of service:

```text
web: gunicorn task_manager.wsgi:application

release: django-admin migrate --noinput
```

Here `web` means the web service, Dokku would use the command to run for our web service.

And `release` is the command which would be run in release stage, here we use the command to migrate our database in release stage.

If you used Celery worker in your project, you can add `worker: ...` to do that.

Add `gunicorn` to dependencies:

```sh
$ poetry add gunicorn
```

### 6.7. requirements.txt file

Check that project has correct `requirements.txt` file in the root of the project.

## 7. Deploy project

Add a remote branch `dokku` to our Git repo:

```
$ git remote add dokku dokku@dokku_ru:monet-web
```

Then push code to remote `master` branch:

```sh
$ git push dokku main
```

Check the output:

```sh
Pseudo-terminal will not be allocated because stdin is not a terminal.
Enumerating objects: 315, done.
Counting objects: 100% (315/315), done.
Delta compression using up to 16 threads
Compressing objects: 100% (306/306), done.
Writing objects: 100% (315/315), 799.12 KiB | 14.02 MiB/s, done.
Total 315 (delta 33), reused 3 (delta 0), pack-reused 0
remote: Resolving deltas: 100% (33/33), done.
-----> Cleaning up...
-----> Building monet-web from herokuish
-----> Adding BUILD_ENV to build environment...
       BUILD_ENV added successfully
-----> Python app detected
-----> Using Python version specified in runtime.txt


...

-----> Updated schedule file
=====> Application deployed:
       http://monet.n8reator.com
       https://monet.n8creator.com
```

Check main domain name to make sure Django app is running without issue.

## 8. Zero Downtime Deploy

When Dokku deploy, it would start container which has the latest code and then wait for 10 secs to make sure the service is ok to run.

To decrease the time, we can add `CHECKS` file and Dokku would use that file to check if our web server is ok to serve.

```text
/admin                      Django
```

It tells Dokku to visit `/admin` url and check if the response contains `Django`.