#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-}"
EXPECT_CONTAINS="${2:-}"

if [ -z "$TARGET_URL" ]; then
  echo "Usage: $0 <preview_url> [expected_substring]" >&2
  exit 2
fi

http_code="$(curl -L -s -o /tmp/one_click_verify_body_$$.txt -w "%{http_code}" "$TARGET_URL")"
if [ "$http_code" != "200" ]; then
  echo "FAIL: HTTP status $http_code for $TARGET_URL" >&2
  exit 1
fi

if [ -n "$EXPECT_CONTAINS" ]; then
  if ! grep -Fq "$EXPECT_CONTAINS" "/tmp/one_click_verify_body_$$.txt"; then
    echo "FAIL: body missing expected text: $EXPECT_CONTAINS" >&2
    exit 1
  fi
fi

echo "PASS: $TARGET_URL (HTTP 200)"
