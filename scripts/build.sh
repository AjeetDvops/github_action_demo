#!/usr/bin/env bash
# Builds the Lambda binary and packages it into a deployable zip artifact.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
BINARY_NAME="bootstrap"
ZIP_NAME="${ZIP_NAME:-lambda.zip}"
GOARCH="${GOARCH:-arm64}"

echo "==> Cleaning ${DIST_DIR}"
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

echo "==> Building Go binary (GOOS=linux GOARCH=${GOARCH})"
cd "${ROOT_DIR}"
CGO_ENABLED=0 GOOS=linux GOARCH="${GOARCH}" go build -trimpath -ldflags="-s -w" \
  -o "${DIST_DIR}/${BINARY_NAME}" ./cmd/lambda

echo "==> Packaging ${ZIP_NAME}"
cd "${DIST_DIR}"
zip -q "${ZIP_NAME}" "${BINARY_NAME}"

echo "==> Build artifact ready: ${DIST_DIR}/${ZIP_NAME}"
