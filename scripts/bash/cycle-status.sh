#!/usr/bin/env bash
# =============================================================================
# cycle-status.sh — Show internet-maintenance cycle marker status
#
# Usage:
#   ./scripts/bash/cycle-status.sh                   # all products in maintenance-defaults.yml
#   ./scripts/bash/cycle-status.sh tdmf-zosmfa       # single product key
#
# Exit codes:
#   0  all checked products are complete (accept marker present)
#   1  one or more products have pending work
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$(cd "$SCRIPT_DIR/../../ansible" && pwd)"
DEFAULTS_FILE="$ANSIBLE_DIR/maintenance-defaults.yml"
LOGS_DIR="$ANSIBLE_DIR/logs"
FILTER="${1:-}"

if [[ ! -f "$DEFAULTS_FILE" ]]; then
  echo "ERROR: $DEFAULTS_FILE not found" >&2
  exit 2
fi

# Parse product keys and their attributes from YAML (no python dependency)
# Format expected: "  key:" lines followed by "    vendor:", "    smpe_csi_dsn:", etc.
declare -A PRODUCT_VENDOR PRODUCT_CSI PRODUCT_DESC
current_key=""
while IFS= read -r line; do
  if [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+): ]] && [[ ! "$line" =~ ":" ]]; then
    current_key="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^[[:space:]]{2}([a-zA-Z0-9_-]+):$ ]]; then
    current_key="${BASH_REMATCH[1]}"
  elif [[ "$line" =~ ^[[:space:]]{2,}([a-zA-Z0-9_-]+):[[:space:]]+(.*) ]]; then
    attr="${BASH_REMATCH[1]}"
    val="${BASH_REMATCH[2]}"
    val="${val//\"/}"  # strip quotes
    case "$attr" in
      vendor)       [[ -n "$current_key" ]] && PRODUCT_VENDOR[$current_key]="$val" ;;
      smpe_csi_dsn) [[ -n "$current_key" ]] && PRODUCT_CSI[$current_key]="$val" ;;
      description)  [[ -n "$current_key" ]] && PRODUCT_DESC[$current_key]="$val" ;;
    esac
  fi
done < "$DEFAULTS_FILE"

# Build list of products to check
declare -a KEYS=()
for k in "${!PRODUCT_VENDOR[@]}"; do
  [[ -n "$FILTER" && "$k" != "$FILTER" ]] && continue
  KEYS+=("$k")
done

if [[ ${#KEYS[@]} -eq 0 ]]; then
  echo "No matching products found${FILTER:+ for key '$FILTER'}."
  exit 2
fi

# Header
printf "\n%-20s %-12s %-48s %-10s %-10s %-10s\n" "PRODUCT" "VENDOR" "CSI" "RECEIVE" "APPLY" "ACCEPT"
printf "%-20s %-12s %-48s %-10s %-10s %-10s\n" "--------------------" "------------" "------------------------------------------------" "--------" "--------" "--------"

pending=0
for key in $(printf '%s\n' "${KEYS[@]}" | sort); do
  vendor="${PRODUCT_VENDOR[$key]:-}"
  csi="${PRODUCT_CSI[$key]:-}"
  [[ -z "$vendor" || -z "$csi" ]] && continue

  csi_key="${csi,,}"          # lowercase
  csi_key="${csi_key//./_}"   # dots → underscores

  rcv_marker="$LOGS_DIR/cycle_${vendor}_${csi_key}_receive.marker"
  apl_marker="$LOGS_DIR/cycle_${vendor}_${csi_key}_apply.marker"
  acc_marker="$LOGS_DIR/cycle_${vendor}_${csi_key}_accept.marker"

  rcv_status="PENDING"
  apl_status="PENDING"
  acc_status="PENDING"

  [[ -f "$rcv_marker" ]] && rcv_status="DONE($(date -r "$rcv_marker" '+%m/%d %H:%M'))"
  [[ -f "$apl_marker" ]] && apl_status="DONE($(date -r "$apl_marker" '+%m/%d %H:%M'))"
  [[ -f "$acc_marker" ]] && acc_status="DONE($(date -r "$acc_marker" '+%m/%d %H:%M'))"

  [[ "$acc_status" == "PENDING" ]] && pending=$((pending+1))

  printf "%-20s %-12s %-48s %-10s %-10s %-10s\n" "$key" "$vendor" "$csi" "$rcv_status" "$apl_status" "$acc_status"
done

echo ""
if [[ $pending -eq 0 ]]; then
  echo "STATUS: All products complete. No maintenance required."
  exit 0
else
  echo "STATUS: $pending product(s) have pending maintenance."
  exit 1
fi
