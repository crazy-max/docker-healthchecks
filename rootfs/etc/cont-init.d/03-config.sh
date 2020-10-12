#!/usr/bin/with-contenv bash

# From https://github.com/docker-library/mariadb/blob/master/docker-entrypoint.sh#L21-L41
# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
  local var="$1"
  local fileVar="${var}_FILE"
  local def="${2:-}"
  if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
    echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
    exit 1
  fi
  local val="$def"
  if [ "${!var:-}" ]; then
    val="${!var}"
  elif [ "${!fileVar:-}" ]; then
    val="$(< "${!fileVar}")"
  fi
  export "$var"="$val"
  unset "$fileVar"
}

TZ=${TZ:-UTC}
DB_TIMEOUT=${DB_TIMEOUT:-60}

# Timezone
echo "Setting timezone to ${TZ}..."
ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime
echo ${TZ} > /etc/timezone

# Settings
echo "Setting Healthchecks configuration..."
sed -i "s|TIME_ZONE = .*|TIME_ZONE = \"${TZ}\"|g" /opt/healthchecks/hc/settings.py

# DB
echo "Checking database..."
if [ -z "$DB" ]; then
  >&2 echo "ERROR: DB must be defined"
  exit 1
fi
if [ "$DB" = "mysql" ]; then
  echo "Use MySQL database"
  if [ -z "${DB_HOST}" ]; then
    >&2 echo "ERROR: DB_HOST must be defined"
    exit 1
  fi
  if [ -z "${DB_NAME}" ]; then
    >&2 echo "ERROR: DB_NAME must be defined"
    exit 1
  fi
  if [ -z "${DB_USER}" ]; then
    >&2 echo "ERROR: DB_USER must be defined"
    exit 1
  fi

  DB_CMD="mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} "-p${DB_PASSWORD}""
  #echo "DB_CMD=$DB_CMD"

  echo "Waiting ${DB_TIMEOUT}s for MySQL database to be ready..."
  counter=1
  while ! ${DB_CMD} -e "show databases;" > /dev/null 2>&1; do
      sleep 1
      counter=$((counter + 1))
      if [ ${counter} -gt "${DB_TIMEOUT}" ]; then
          >&2 echo "ERROR: Failed to connect to MySQL database on $DB_HOST"
          exit 1
      fi;
  done
  echo "MySQL database ready!"
elif [ "$DB" = "postgres" ]; then
  echo "Use PostgreSQL database"
  if [ -z "${DB_HOST}" ]; then
    >&2 echo "ERROR: DB_HOST must be defined"
    exit 1
  fi
  if [ -z "${DB_NAME}" ]; then
    >&2 echo "ERROR: DB_NAME must be defined"
    exit 1
  fi
  if [ -z "${DB_USER}" ]; then
    >&2 echo "ERROR: DB_USER must be defined"
    exit 1
  fi

  DB_CMD="psql --host=${DB_HOST} --port=${DB_PORT} --username=${DB_USER} -lqt"
  #echo "DB_CMD=$DB_CMD"

  echo "Waiting ${DB_TIMEOUT}s for database to be ready..."
  counter=1
  while ${DB_CMD} | cut -d \| -f 1 | grep -qw "${DB_NAME}" > /dev/null 2>&1; [ $? -ne 0 ]; do
    sleep 1
    counter=$((counter + 1))
    if [ ${counter} -gt "${DB_TIMEOUT}" ]; then
      >&2 echo "ERROR: Failed to connect to PostgreSQL database on $DB_HOST"
      exit 1
    fi;
  done
  echo "PostgreSQL database ready!"
elif [ "$DB" = "sqlite" ]; then
  echo "Use SQLite database"
  if [ -z "${DB_NAME}" ]; then
    >&2 echo "ERROR: DB_NAME must be defined"
    exit 1
  fi
  if [ ! -f "/opt/healthchecks/hc.sqlite" ]; then
    su-exec healthchecks:healthchecks ln -sf /data/hc.sqlite /opt/healthchecks/hc.sqlite
  fi
else
  >&2 echo "ERROR: Unknown database type: $DB"
  exit 1
fi

# Migrate database
echo "Migrating database..."
su-exec healthchecks:healthchecks python /opt/healthchecks/manage.py migrate --noinput

# Create superuser
file_env 'SUPERUSER_PASSWORD'
if [ -n "$SUPERUSER_EMAIL" ] && [ -n "$SUPERUSER_PASSWORD" ]; then
  cat << EOF | su-exec healthchecks:healthchecks python /opt/healthchecks/manage.py shell
from django.contrib.auth.models import User;
username = 'su';
password = '$SUPERUSER_PASSWORD';
email = '$SUPERUSER_EMAIL';
if User.objects.filter(username=username).count()==0:
  User.objects.create_superuser(username, email, password);
  print('Superuser created successfully!');
else:
  print('Superuser already exists.');
EOF
fi

if [ ! "$(ls -A /data/img)" ]; then
  echo "Copying img to /opt/healthchecks/static/img/..."
  su-exec healthchecks:healthchecks cp -rf /data/img/* /opt/healthchecks/static/img/
fi
