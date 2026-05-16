#!/usr/bin/env bash
# helpers/create-mysql-db.sh — Create a MySQL database + user in the PXC cluster.
#
# Usage:
#   ./helpers/create-mysql-db.sh <db_name> [password]
#
# If password is omitted, a random 48-char hex password is generated.
#
# How it works:
#   Execs mysql directly inside the running PXC pod (bypasses NetworkPolicy).
#   Creates the database and user (idempotent — safe to re-run).
#
# Example:
#   ./helpers/create-mysql-db.sh myapp
#   ./helpers/create-mysql-db.sh myapp s3cur3p4ss

set -euo pipefail

DB_NAME="${1:?Usage: create-mysql-db.sh <db_name> [password]}"
DB_PASSWORD="${2:-$(openssl rand -hex 24)}"
NAMESPACE="pxc-clusters"
POD="mysql-pxc-db-pxc-0"

echo "━━━ Creating MySQL database '${DB_NAME}' in PXC cluster ━━━"
echo "  User:     ${DB_NAME}"
echo "  Password: ${DB_PASSWORD}"
echo "  Host:     mysql-pxc-db-haproxy.${NAMESPACE}.svc:3306"
echo ""

# Extract root password from the PXC secrets.
ROOT_PASS=$(kubectl get secret mysql-pxc-db-secrets -n "${NAMESPACE}" -o jsonpath='{.data.root}' | base64 -d)

# Build the SQL.
SQL="CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`;
CREATE USER IF NOT EXISTS '${DB_NAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
ALTER USER '${DB_NAME}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_NAME}'@'%';
FLUSH PRIVILEGES;"

echo "⏳ Executing SQL in pod ${POD}..."
echo "${SQL}" | kubectl exec -i -n "${NAMESPACE}" "${POD}" -- mysql -u root -p"${ROOT_PASS}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ MySQL database '${DB_NAME}' ready!"
echo ""
echo "  Connection string:"
echo "    mysql://${DB_NAME}:${DB_PASSWORD}@mysql-pxc-db-haproxy.${NAMESPACE}.svc:3306/${DB_NAME}"
echo ""
echo "  For use in a Kubernetes Secret:"
echo "    DB_HOST: mysql-pxc-db-haproxy.${NAMESPACE}.svc"
echo "    DB_PORT: \"3306\""
echo "    DB_USER: ${DB_NAME}"
echo "    DB_PASSWORD: ${DB_PASSWORD}"
echo "    DB_NAME: ${DB_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
