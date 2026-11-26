#!/usr/bin/env bash
# =============================================================================
# setup-zowe-profile.sh
# Installs the Zowe team config for the applied-ai-general-toolbox toolchain.
# Target:  Linux control node
# Profile: dcuf  →  138.69.218.201 (z/OSMF :443)
# Usage:   bash setup-zowe-profile.sh
# =============================================================================

set -euo pipefail

ZOWE_CONFIG_DIR="/home/a463476/repos/applied-ai-general-toolbox"
ZOWE_CONFIG_FILE="$ZOWE_CONFIG_DIR/zowe.config.json"

echo "──────────────────────────────────────────────"
echo " Zowe Profile Setup — DCUF (138.69.218.201)"
echo "──────────────────────────────────────────────"

# ── 1. Prerequisite check ─────────────────────────────────────────────────────
if ! command -v zowe &>/dev/null; then
  echo "ERROR: Zowe CLI not found. Install it first:"
  echo "  npm install -g @zowe/cli"
  echo "  zowe plugins install @zowe/zos-jobs-for-zowe-cli"
  echo "  zowe plugins install @zowe/zos-files-for-zowe-cli"
  exit 1
fi

echo "✔  Zowe CLI found: $(zowe --version)"

# ── 2. Create config directory ────────────────────────────────────────────────
mkdir -p "$ZOWE_CONFIG_DIR"
echo "✔  Config directory: $ZOWE_CONFIG_DIR"

# ── 3. Write zowe.config.json ─────────────────────────────────────────────────
cat > "$ZOWE_CONFIG_FILE" << 'ZOWECONFIG'
{
  "$schema": "./zowe.schema.json",
  "profiles": {
    "dcuf": {
      "type": "zosmf",
      "properties": {
        "host": "localhost",
        "port": 443,
        "basePath": "/zosmf",
        "rejectUnauthorized": false,
        "protocol": "https"
      },
      "secure": [
        "user",
        "password"
      ]
    },
    "dcuf_ssh": {
      "type": "ssh",
      "properties": {
        "host": "138.69.218.201",
        "port": 22,
        "user": "syssa69"
      },
      "secure": [
        "privateKey"
      ]
    },
    "dcub": {
      "type": "zosmf",
      "properties": {
        "host": "localhost",
        "port": 443,
        "basePath": "/zosmf",
        "rejectUnauthorized": false,
        "protocol": "https"
      },
      "secure": [
        "user",
        "password"
      ]
    }
  },
  "defaults": {
    "zosmf": "dcuf",
    "ssh": "dcuf_ssh"
  },
  "autoStore": true
}
ZOWECONFIG

echo "✔  Written: $ZOWE_CONFIG_FILE"

# ── 4. Store credentials in OS keystore ──────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────"
echo " Storing credentials (Zowe secure credential store)"
echo "──────────────────────────────────────────────"

# z/OSMF credentials for dcuf
read -r -p "z/OSMF username for DCUF [syssa69]: " ZOSMF_USER
ZOSMF_USER="${ZOSMF_USER:-syssa69}"

read -r -s -p "z/OSMF password for $ZOSMF_USER: " ZOSMF_PASS
echo ""

zowe config set "profiles.dcuf.properties.user" "$ZOSMF_USER" \
  --config-file "$ZOWE_CONFIG_FILE" --secure
zowe config set "profiles.dcuf.properties.password" "$ZOSMF_PASS" \
  --config-file "$ZOWE_CONFIG_FILE" --secure

echo "✔  z/OSMF credentials stored for profile: dcuf"

# SSH private key for dcuf_ssh
read -r -p "Path to SSH private key [~/.ssh/id_zos]: " SSH_KEY
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_zos}"

if [[ ! -f "$SSH_KEY" ]]; then
  echo "WARNING: SSH key not found at $SSH_KEY — skipping SSH profile credential"
  echo "         Run this manually when the key exists:"
  echo "         zowe config set profiles.dcuf_ssh.properties.privateKey '$SSH_KEY' --config-file $ZOWE_CONFIG_FILE --secure"
else
  zowe config set "profiles.dcuf_ssh.properties.privateKey" "$SSH_KEY" \
    --config-file "$ZOWE_CONFIG_FILE" --secure
  echo "✔  SSH private key stored for profile: dcuf_ssh"
fi

# ── 5. Test z/OSMF connectivity ───────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────"
echo " Testing z/OSMF connectivity..."
echo "──────────────────────────────────────────────"

if zowe zosmf check status --config-file "$ZOWE_CONFIG_FILE" 2>&1; then
  echo ""
  echo "✔  z/OSMF connection to DCUF (138.69.218.201) is SUCCESSFUL"
else
  echo ""
  echo "⚠  z/OSMF connection test failed."
  echo "   Check: host reachability, z/OSMF started task (IZUSVR1), port 443, SSL cert"
fi

# ── 6. Test job listing (Zowe JES) ────────────────────────────────────────────
echo ""
echo "──────────────────────────────────────────────"
echo " Testing JES job listing (owner=$ZOSMF_USER)..."
echo "──────────────────────────────────────────────"

zowe jobs list jobs --owner "$ZOSMF_USER" --config-file "$ZOWE_CONFIG_FILE" \
  2>&1 | head -20 || true

echo ""
echo "══════════════════════════════════════════════"
echo " Setup complete."
echo " Config file : $ZOWE_CONFIG_FILE"
echo " Default profile : dcuf (zosmf)"
echo " Default SSH profile : dcuf_ssh"
echo ""
echo " To use with the sdt-maintenance-refresh-agent:"
echo "   The agent reads this config automatically."
echo "   Run in VS Code Copilot Chat: @sdt-maintenance-refresh-agent start"
echo "══════════════════════════════════════════════"
