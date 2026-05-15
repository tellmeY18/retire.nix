#!/usr/bin/env bash
# helpers/create-db.sh — Create a PostgreSQL database + user in the CNPG cluster.
#
# Usage:
#   ./helpers/create-db.sh <db_name> [password]
#
# If password is omitted, a random 48-char hex password is generated.
#
# Prerequisites:
#   - CNPG cluster with enableSuperuserAccess: true
#   - Secret `postgres-cluster-superuser` exists in cnpg-clusters namespace
#   - kubectl access to the cluster
#
# What it does:
#   1. Generates a one-time Kubernetes Job that connects as superuser
#   2. Creates the database and role (idempotent — safe to re-run)
#   3. Waits for completion, prints the connection string, cleans up
#
# Example:
#   ./helpers/create-db.sh answer
#   ./helpers/create-db.sh myapp s3cur3p4ss

set -euo pipefail

DB_NAME="${1:?Usage: create-db.sh <db_name> [password]}"
DB_PASSWORD="${2:-$(openssl rand -hex 24)}"
JOB_NAME="create-db-${DB_NAME}"
NAMESPACE="cnpg-clusters"

echo "━━━ Creating database '${DB_NAME}' in CNPG cluster ━━━"
echo "  User:     ${DB_NAME}"
echo "  Password: ${DB_PASSWORD}"
echo "  Host:     postgres-cluster-rw.cnpg-clusters.svc:5432"
echo ""

# Generate and apply the Job manifest.
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: ${NAMESPACE}
  labels:
    app.kubernetes.io/component: db-provisioning
spec:
  ttlSecondsAfterFinished: 120
  template:
    spec:
      restartPolicy: OnFailure
      securityContext:
        runAsNonRoot: true
        runAsUser: 70
        runAsGroup: 70
        fsGroup: 70
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: psql
          image: postgres:17-alpine
          command: ["/bin/sh", "-c"]
          args:
            - |
              set -eu
              echo "Connecting to CNPG cluster..."
              psql "\${PGURI}" -c "DO \$\$BEGIN IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${DB_NAME}') THEN CREATE ROLE ${DB_NAME} WITH LOGIN PASSWORD '${DB_PASSWORD}'; ELSE ALTER ROLE ${DB_NAME} WITH PASSWORD '${DB_PASSWORD}'; END IF; END\$\$;"
              psql "\${PGURI}" -c "SELECT 'CREATE DATABASE ${DB_NAME} OWNER ${DB_NAME}' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${DB_NAME}')" -t | grep -q CREATE && psql "\${PGURI}" -c "CREATE DATABASE ${DB_NAME} OWNER ${DB_NAME}" || true
              psql "\${PGURI}" -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_NAME}"
              echo "Done."
          env:
            - name: PGURI
              valueFrom:
                secretKeyRef:
                  name: postgres-cluster-superuser
                  key: uri
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop: ["ALL"]
EOF

echo "⏳ Waiting for job to complete..."
kubectl wait --for=condition=complete "job/${JOB_NAME}" -n "${NAMESPACE}" --timeout=90s

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Database '${DB_NAME}' ready!"
echo ""
echo "  Connection string:"
echo "    postgresql://${DB_NAME}:${DB_PASSWORD}@postgres-cluster-rw.cnpg-clusters.svc:5432/${DB_NAME}"
echo ""
echo "  For use in a Kubernetes Secret:"
echo "    DB_HOST: postgres-cluster-rw.cnpg-clusters.svc"
echo "    DB_PORT: \"5432\""
echo "    DB_USER: ${DB_NAME}"
echo "    DB_PASSWORD: ${DB_PASSWORD}"
echo "    DB_NAME: ${DB_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Cleanup
kubectl delete "job/${JOB_NAME}" -n "${NAMESPACE}" --ignore-not-found >/dev/null 2>&1 &
