#!/usr/bin/env bash
# helpers/create-db.sh — Create a PostgreSQL database + user in the CNPG cluster.
#
# Usage:
#   ./helpers/create-db.sh <db_name> [password]
#
# If password is omitted, a random 48-char hex password is generated.
#
# How it works:
#   Execs psql directly inside a running CNPG pod (bypasses NetworkPolicy
#   and avoids Job/container escaping hell). The superuser URI is extracted
#   from the postgres-cluster-superuser Secret.
#
# Example:
#   ./helpers/create-db.sh answer
#   ./helpers/create-db.sh myapp s3cur3p4ss

set -euo pipefail

DB_NAME="${1:?Usage: create-db.sh <db_name> [password]}"
DB_PASSWORD="${2:-$(openssl rand -hex 24)}"
NAMESPACE="cnpg-clusters"
POD="postgres-cluster-1"

echo "━━━ Creating database '${DB_NAME}' in CNPG cluster ━━━"
echo "  User:     ${DB_NAME}"
echo "  Password: ${DB_PASSWORD}"
echo "  Host:     postgres-cluster-rw.${NAMESPACE}.svc:5432"
echo ""

# Build the SQL.
SQL=$(cat <<EOSQL
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_NAME}') THEN
    CREATE ROLE ${DB_NAME} WITH LOGIN PASSWORD '${DB_PASSWORD}';
    RAISE NOTICE 'Created role ${DB_NAME}';
  ELSE
    ALTER ROLE ${DB_NAME} WITH PASSWORD '${DB_PASSWORD}';
    RAISE NOTICE 'Role ${DB_NAME} exists, password updated';
  END IF;
END
\$\$;

SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_NAME}'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')\gexec

GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_NAME};
EOSQL
)

echo "⏳ Executing SQL in pod ${POD}..."
kubectl exec -n "${NAMESPACE}" "${POD}" -- psql -U postgres -c "${SQL}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Database '${DB_NAME}' ready!"
echo ""
echo "  Connection string:"
echo "    postgresql://${DB_NAME}:${DB_PASSWORD}@postgres-cluster-rw.${NAMESPACE}.svc:5432/${DB_NAME}"
echo ""
echo "  For use in a Kubernetes Secret:"
echo "    DB_HOST: postgres-cluster-rw.${NAMESPACE}.svc"
echo "    DB_PORT: \"5432\""
echo "    DB_USER: ${DB_NAME}"
echo "    DB_PASSWORD: ${DB_PASSWORD}"
echo "    DB_NAME: ${DB_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
