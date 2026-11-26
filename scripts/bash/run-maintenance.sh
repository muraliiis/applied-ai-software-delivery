#!/usr/bin/env bash
# =============================================================================
# run-maintenance.sh — Direct execution wrapper for internet-maintenance.yml
#
# Reads product definitions from ansible/maintenance-defaults.yml.
# Pre-checks cycle markers — skips Ansible entirely if cycle is already complete.
# No LLM / interactive prompts required.
#
# Usage:
#   ./scripts/bash/run-maintenance.sh [product-key]   # single product
#   ./scripts/bash/run-maintenance.sh                 # all products in sequence
#
# Resume / cycle reset:
#   rm ansible/logs/cycle_{vendor}_{csi_key}_*.marker   # reset one product
#   rm ansible/logs/cycle_*.marker                       # reset all
#
# Exit codes:
#   0  all products processed (or already complete)
#   1  one or more products failed
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/../../ansible" && pwd)"
DEFAULTS_FILE="$ANSIBLE_DIR/maintenance-defaults.yml"
LOGS_DIR="$ANSIBLE_DIR/logs"
FILTER="${1:-}"

if [[ ! -f "$DEFAULTS_FILE" ]]; then
  echo "ERROR: $DEFAULTS_FILE not found" >&2
  exit 2
fi

# ── Parse maintenance-defaults.yml ────────────────────────────────────────────
declare -A PRODUCT_VENDOR PRODUCT_CSI PRODUCT_TZONE PRODUCT_DZONE PRODUCT_DESC
current_key=""
while IFS= read -r line; do
  # Top-level product key (2-space indent, ends with colon, no value)
  if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+):$ ]]; then
    current_key="${BASH_REMATCH[1]}"
    [[ "$current_key" == "maintenance_products" ]] && current_key=""
  elif [[ "$line" =~ ^[[:space:]]{4}([a-zA-Z0-9_]+):[[:space:]]+(.*) ]] && [[ -n "$current_key" ]]; then
    attr="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    val="${val//\"/}"
    case "$attr" in
      vendor)           PRODUCT_VENDOR[$current_key]="$val" ;;
      smpe_csi_dsn)     PRODUCT_CSI[$current_key]="$val" ;;
      smpe_target_zone) PRODUCT_TZONE[$current_key]="$val" ;;
      smpe_dlib_zone)   PRODUCT_DZONE[$current_key]="$val" ;;
      description)      PRODUCT_DESC[$current_key]="$val" ;;
    esac
  fi
done < "$DEFAULTS_FILE"

# ── Build product list ────────────────────────────────────────────────────────
declare -a KEYS=()
for k in "${!PRODUCT_VENDOR[@]}"; do
  [[ -n "$FILTER" && "$k" != "$FILTER" ]] && continue
  KEYS+=("$k")
done

if [[ ${#KEYS[@]} -eq 0 ]]; then
  echo "No matching products found${FILTER:+ for key '$FILTER'}." >&2
  exit 2
fi

overall_rc=0

for key in $(printf '%s\n' "${KEYS[@]}" | sort); do
  vendor="${PRODUCT_VENDOR[$key]:-}"
  csi="${PRODUCT_CSI[$key]:-}"
  tzone="${PRODUCT_TZONE[$key]:-}"
  dzone="${PRODUCT_DZONE[$key]:-}"
  desc="${PRODUCT_DESC[$key]:-$key}"

  if [[ -z "$vendor" || -z "$csi" || -z "$tzone" || -z "$dzone" ]]; then
    echo "WARN: Skipping '$key' — missing required fields (vendor/smpe_csi_dsn/smpe_target_zone/smpe_dlib_zone)" >&2
    continue
  fi

  csi_key="${csi,,}"
  csi_key="${csi_key//./_}"
  acc_marker="$LOGS_DIR/cycle_${vendor}_${csi_key}_accept.marker"

  echo ""
  echo "══════════════════════════════════════════════════════"
  echo " Product  : $key"
  echo " Desc     : $desc"
  echo " Vendor   : $vendor"
  echo " CSI      : $csi"
  echo " Zones    : $tzone / $dzone"
  echo "══════════════════════════════════════════════════════"

  # ── Pre-check: skip if cycle already complete ────────────────────────────
  if [[ -f "$acc_marker" ]]; then
    acc_ts="$(date -r "$acc_marker" '+%Y-%m-%d %H:%M')"
    echo " STATUS   : COMPLETE (cycle marker written $acc_ts)"
    echo " ACTION   : Nothing to do. To start a new cycle:"
    echo "            rm $LOGS_DIR/cycle_${vendor}_${csi_key}_*.marker"
    echo "══════════════════════════════════════════════════════"
    continue
  fi

  echo " STATUS   : PENDING — launching playbook..."
  echo "══════════════════════════════════════════════════════"
  echo ""

  # ── Run Ansible playbook (no vars_prompt — all vars via -e) ──────────────
  pushd "$ANSIBLE_DIR" > /dev/null
  set +e
  ansible-playbook playbooks/internet-maintenance.yml \
    -e "vendor=${vendor}" \
    -e "smpe_csi_dsn=${csi}" \
    -e "smpe_target_zone_input=${tzone}" \
    -e "smpe_dlib_zone_input=${dzone}"
  playbook_rc=$?
  set -e
  popd > /dev/null

  if [[ $playbook_rc -ne 0 ]]; then
    echo ""
    echo "ERROR: Playbook for '$key' exited with RC=$playbook_rc"
    overall_rc=1
  fi
done

echo ""
if [[ $overall_rc -eq 0 ]]; then
  echo "All maintenance runs completed successfully."
else
  echo "One or more maintenance runs failed — check output above."
fi
exit $overall_rc
