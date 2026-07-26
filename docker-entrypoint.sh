#!/usr/bin/env sh
set -e

if [ -n "${APP_JWK_KEYSTORE_BASE64:-}" ]; then
  mkdir -p /app/secrets
  printf '%s' "$APP_JWK_KEYSTORE_BASE64" | base64 -d > /app/secrets/jwk.p12
  export APP_JWK_KEYSTORE_LOCATION=file:/app/secrets/jwk.p12
fi

exec java -jar app.jar
