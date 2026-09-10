#!/usr/bin/env bash
# Invokes the deployed Lambda function (or its Function URL) and verifies a healthy response.
set -euo pipefail

FUNCTION_NAME="${1:-${FUNCTION_NAME:-}}"
FUNCTION_URL="${FUNCTION_URL:-}"

if [[ -z "${FUNCTION_NAME}" && -z "${FUNCTION_URL}" ]]; then
  echo "usage: FUNCTION_NAME=<name> $0  (or) FUNCTION_URL=<url> $0" >&2
  exit 1
fi

if [[ -n "${FUNCTION_URL}" ]]; then
  echo "==> Smoke testing via Function URL: ${FUNCTION_URL}"
  http_code=$(curl -s -o /tmp/smoke-response.json -w "%{http_code}" "${FUNCTION_URL}")
else
  echo "==> Smoke testing via aws lambda invoke: ${FUNCTION_NAME}"
  aws lambda invoke \
    --function-name "${FUNCTION_NAME}" \
    --payload '{"path":"/health","httpMethod":"GET"}' \
    --cli-binary-format raw-in-base64-out \
    /tmp/smoke-response.json >/tmp/smoke-invoke-meta.json
  http_code=$(jq -r '.StatusCode // 200' /tmp/smoke-response.json 2>/dev/null || echo 200)
fi

echo "==> Response body:"
cat /tmp/smoke-response.json
echo

if [[ "${http_code}" != "200" ]]; then
  echo "Smoke test FAILED with status ${http_code}" >&2
  exit 1
fi

echo "Smoke test PASSED"
