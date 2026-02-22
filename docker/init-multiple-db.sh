#!/bin/bash
set -e

# This script creates multiple databases when the container first starts.
# It reads the POSTGRES_MULTIPLE_DATABASES env variable.

if [ -n "$POSTGRES_MULTIPLE_DATABASES" ]; then
  echo "Creating multiple databases: $POSTGRES_MULTIPLE_DATABASES"

  for db in $(echo $POSTGRES_MULTIPLE_DATABASES | tr ',' ' '); do
    echo "Creating database: $db"
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
      SELECT 'CREATE DATABASE $db' WHERE NOT EXISTS (
        SELECT FROM pg_database WHERE datname = '$db'
      )\gexec
EOSQL
  done
fi
