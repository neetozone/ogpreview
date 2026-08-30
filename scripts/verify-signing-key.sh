#!/usr/bin/env bash
# Fail loudly when the key we would sign with is not the key installed copies
# trust. That mismatch is what a laptop change causes, and Sparkle reports it to
# users as nothing at all: updates simply stop arriving.
#
#   scripts/verify-signing-key.sh                    # check the local keychain key
#   scripts/verify-signing-key.sh private-key.txt    # check a key file (CI)
set -euo pipefail
cd "$(dirname "$0")/.."

KEY_FILE="${1:-}"
PLIST="${2:-ogpreview.app/Contents/Info.plist}"

TOOL=".build/artifacts/sparkle/Sparkle/bin/generate_keys"

if [ -z "$KEY_FILE" ]; then
  [ -x "$TOOL" ] || { echo "FAIL: $TOOL not found — run 'swift build' first."; exit 1; }

  # generate_keys refuses to overwrite, so hand it a path inside a fresh dir.
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  KEY_FILE="$TMP_DIR/sparkle.key"

  "$TOOL" --account neetozone -x "$KEY_FILE" >/dev/null 2>&1 || true
  [ -s "$KEY_FILE" ] \
    || { echo "FAIL: no Sparkle key on the 'neetozone' keychain account."; \
         echo "      On a new machine, import the backup — do NOT let it generate a new key:"; \
         echo "      $TOOL --account neetozone -f key.txt"; \
         exit 1; }
fi

[ -f "$PLIST" ] || { echo "FAIL: $PLIST not found — run scripts/make-app.sh first."; exit 1; }

derived="$(swift scripts/derive-public-key.swift "$KEY_FILE")"
shipped="$(/usr/libexec/PlistBuddy -c 'Print :SUPublicEDKey' "$PLIST")"

if [ "$derived" != "$shipped" ]; then
  echo "FAIL: the signing key does not match the app."
  echo "  the app trusts:  $shipped"
  echo "  this key signs:  $derived"
  echo
  echo "Every installed copy would reject this update. See README > Signing key."
  exit 1
fi

echo "PASS: signing key matches the app ($shipped)"
