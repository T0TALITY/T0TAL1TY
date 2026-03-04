#!/usr/bin/env bash
# ===========================================================
# TOTALITY ONE-STEP DEPLOY SCRIPT
# Supports pre-publish zip/tar bundles and launches master script
# ===========================================================

set -euo pipefail

log() { echo "🔹 $1"; }
warn() { echo "⚠️ $1"; }
fail() { echo "❌ $1"; exit 1; }

echo
echo "🚀 TOTALITY — ONE-STEP DEPLOY"
echo

if ! command -v pkg >/dev/null 2>&1; then
  warn "This script is optimized for Termux (pkg not found). Continuing with existing tools..."
fi

# 1) Optional Termux setup (safe no-op elsewhere)
if command -v termux-setup-storage >/dev/null 2>&1; then
  termux-setup-storage >/dev/null 2>&1 || true
fi
if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock || true
fi
log "Storage and wake-lock step completed"

# 2) Dependencies
DEPS=(git wget curl unzip rsync tar sha256sum)
for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    if command -v pkg >/dev/null 2>&1; then
      log "Installing missing package: $dep"
      pkg install -y "$dep"
    else
      fail "Missing required dependency: $dep"
    fi
  fi
done

if ! command -v python >/dev/null 2>&1 && ! command -v python3 >/dev/null 2>&1; then
  if command -v pkg >/dev/null 2>&1; then
    log "Installing missing package: python"
    pkg install -y python
  else
    fail "Missing required dependency: python/python3"
  fi
fi

for opt_dep in redis-server flutter; do
  if ! command -v "$opt_dep" >/dev/null 2>&1; then
    warn "Optional dependency not found: $opt_dep"
  fi
done

TARGET_DIR="$HOME/TOTALITY_RELEASE_BUILD"
LOG_DIR="$TARGET_DIR/logs"
PACKAGE_TAR="TOTALITY_RELEASE_PACKAGE.tar.gz"
CHECKSUM="TOTALITY_RELEASE_PACKAGE.sha256"
PACKAGE_ZIP="TOTALITY_PrePublish_Bundle.zip"
MASTER_SCRIPT=""

extract_bundle() {
  mkdir -p "$TARGET_DIR"
  rm -rf "$TARGET_DIR"/*

  if [[ -f "$PACKAGE_TAR" ]]; then
    log "Found tar release package"
    if [[ -f "$CHECKSUM" ]]; then
      log "Verifying SHA256 checksum..."
      sha256sum -c "$CHECKSUM"
    else
      warn "Checksum file not found; continuing without hash verification"
    fi
    log "Extracting tar package..."
    tar -xzvf "$PACKAGE_TAR" -C "$TARGET_DIR"
    return
  fi

  if [[ -f "$PACKAGE_ZIP" ]]; then
    log "Found pre-publish zip bundle"
    log "Extracting zip package..."
    unzip -o "$PACKAGE_ZIP" -d "$TARGET_DIR"
    return
  fi

  fail "No supported package found. Expected $PACKAGE_TAR or $PACKAGE_ZIP"
}

validate_prepublish_layout() {
  if [[ -f "$TARGET_DIR/metadata.json" ]]; then
    log "Detected pre-publish metadata.json"

    [[ -f "$TARGET_DIR/Master_Thesis.pdf" || -f "$TARGET_DIR/Master_Thesis.tex" ]] || \
      fail "Pre-publish bundle missing Master_Thesis.pdf/.tex"

    [[ -d "$TARGET_DIR/scripts" ]] || fail "Pre-publish bundle missing scripts/"
    [[ -d "$TARGET_DIR/supplementary" ]] || fail "Pre-publish bundle missing supplementary/"

    if [[ -f "$TARGET_DIR/scripts/one_click_publish.sh" ]]; then
      MASTER_SCRIPT="$TARGET_DIR/scripts/one_click_publish.sh"
    elif [[ -f "$TARGET_DIR/scripts/publish.sh" ]]; then
      MASTER_SCRIPT="$TARGET_DIR/scripts/publish.sh"
    fi
  fi
}

resolve_master_script() {
  # Standard release locations
  if [[ -z "$MASTER_SCRIPT" ]]; then
    if [[ -f "$TARGET_DIR/TOTALITY_MASTER_RELEASE.sh" ]]; then
      MASTER_SCRIPT="$TARGET_DIR/TOTALITY_MASTER_RELEASE.sh"
    elif [[ -f "$TARGET_DIR/scripts/TOTALITY_MASTER_RELEASE.sh" ]]; then
      MASTER_SCRIPT="$TARGET_DIR/scripts/TOTALITY_MASTER_RELEASE.sh"
    fi
  fi

  [[ -n "$MASTER_SCRIPT" && -f "$MASTER_SCRIPT" ]] || \
    fail "Master release script not found after extraction"
}

extract_bundle
validate_prepublish_layout
resolve_master_script

log "Applying execute permissions..."
chmod -R u+x "$TARGET_DIR"
mkdir -p "$LOG_DIR"

log "Launching: $MASTER_SCRIPT"
nohup bash "$MASTER_SCRIPT" >"$LOG_DIR/deploy-nohup.log" 2>&1 &
echo "✅ TOTALITY launched successfully!"

echo
echo "📦 TOTALITY is now live!"
echo "Logs: $LOG_DIR/"
echo "PDF docs: $TARGET_DIR/TOTALITY_FULL_BUILD.pdf"
echo "Bundle thesis: $TARGET_DIR/Master_Thesis.pdf"
echo
echo "💡 Stop helpers: pkill -f python; pkill -f celery; pkill -f redis-server"
