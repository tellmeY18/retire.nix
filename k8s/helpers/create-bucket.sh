#!/usr/bin/env bash
# helpers/create-bucket.sh — Create an S3 bucket + dedicated user in RustFS.
#
# Usage:
#   ./helpers/create-bucket.sh <bucket_name> [access_key] [secret_key]
#
# If keys are omitted, random ones are generated.
#
# How it works:
#   Execs mc directly inside a running RustFS pod (bypasses NetworkPolicy).
#   Creates the bucket, an IAM policy scoped to it, and a dedicated user.
#
# Example:
#   ./helpers/create-bucket.sh answer
#   ./helpers/create-bucket.sh myapp myAccessKey mySecretKey

set -euo pipefail

BUCKET="${1:?Usage: create-bucket.sh <bucket_name> [access_key] [secret_key]}"
ACCESS_KEY="${2:-$(openssl rand -hex 16)}"
SECRET_KEY="${3:-$(openssl rand -hex 32)}"
NAMESPACE="rustfs-clusters"
POD="rustfs-0"
ALIAS="local"

echo "━━━ Creating bucket '${BUCKET}' in RustFS ━━━"
echo "  Access Key: ${ACCESS_KEY}"
echo "  Secret Key: ${SECRET_KEY}"
echo "  Endpoint:   http://rustfs-storage-io.${NAMESPACE}.svc:9000"
echo ""

# Get root credentials from the rustfs-credentials secret.
ROOT_AK=$(kubectl get secret rustfs-credentials -n "${NAMESPACE}" -o jsonpath='{.data.accesskey}' | base64 -d)
ROOT_SK=$(kubectl get secret rustfs-credentials -n "${NAMESPACE}" -o jsonpath='{.data.secretkey}' | base64 -d)

echo "⏳ Configuring mc inside pod ${POD}..."

# All mc commands exec'd inside the RustFS pod (has mc baked in).
kubectl exec -n "${NAMESPACE}" "${POD}" -- sh -c "
  export MC_CONFIG_DIR=/tmp/.mc-\$\$
  mc alias set ${ALIAS} http://localhost:9000 '${ROOT_AK}' '${ROOT_SK}' >/dev/null 2>&1

  echo 'Creating bucket...'
  mc mb --ignore-existing ${ALIAS}/${BUCKET}
  mc anonymous set none ${ALIAS}/${BUCKET}

  echo 'Creating IAM policy...'
  cat > /tmp/${BUCKET}-policy.json <<'POLICY'
{
  \"Version\": \"2012-10-17\",
  \"Statement\": [{
    \"Effect\": \"Allow\",
    \"Action\": [\"s3:GetObject\",\"s3:PutObject\",\"s3:DeleteObject\",\"s3:ListBucket\",\"s3:GetBucketLocation\"],
    \"Resource\": [\"arn:aws:s3:::${BUCKET}\",\"arn:aws:s3:::${BUCKET}/*\"]
  }]
}
POLICY
  mc admin policy create ${ALIAS} ${BUCKET}-rw /tmp/${BUCKET}-policy.json 2>/dev/null || \
    mc admin policy info ${ALIAS} ${BUCKET}-rw >/dev/null 2>&1

  echo 'Creating user...'
  mc admin user add ${ALIAS} '${ACCESS_KEY}' '${SECRET_KEY}' 2>/dev/null || true
  mc admin policy attach ${ALIAS} ${BUCKET}-rw --user '${ACCESS_KEY}' 2>/dev/null || true

  rm -rf /tmp/.mc-\$\$ /tmp/${BUCKET}-policy.json
  echo 'Done.'
"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ Bucket '${BUCKET}' ready!"
echo ""
echo "  S3 Endpoint:  http://rustfs-storage-io.${NAMESPACE}.svc:9000"
echo "  Bucket:       ${BUCKET}"
echo "  Access Key:   ${ACCESS_KEY}"
echo "  Secret Key:   ${SECRET_KEY}"
echo ""
echo "  For use in a Kubernetes Secret:"
echo "    S3_ENDPOINT: http://rustfs-storage-io.${NAMESPACE}.svc:9000"
echo "    S3_BUCKET: ${BUCKET}"
echo "    S3_ACCESS_KEY: ${ACCESS_KEY}"
echo "    S3_SECRET_KEY: ${SECRET_KEY}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
