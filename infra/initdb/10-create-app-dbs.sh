#!/usr/bin/env sh
set -eu

create_role_if_missing() {
  role="$1"
  pass="$2"
  exists=$(psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='${role}'")
  if [ "$exists" != "1" ]; then
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "CREATE ROLE ${role} LOGIN PASSWORD '${pass}';"
  fi
}

create_db_if_missing() {
  db="$1"
  owner="$2"
  exists=$(psql -U "$POSTGRES_USER" -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='${db}'")
  if [ "$exists" != "1" ]; then
    psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE ${db} OWNER ${owner};"
  fi
}

create_role_if_missing "${MM_DB_USER}" "${MM_DB_PASSWORD}"
create_role_if_missing "${VK_DB_USER}" "${VK_DB_PASSWORD}"

create_db_if_missing "${MM_DB_NAME}" "${MM_DB_USER}"
create_db_if_missing "${VK_DB_NAME}" "${VK_DB_USER}"
