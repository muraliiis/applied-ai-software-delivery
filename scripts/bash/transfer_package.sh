#!/bin/bash
#
# Package Transfer Script
# Transfers Shopz packages from Linux staging to z/OS target LPAR
#
# Usage: ./transfer_package.sh <package_id> <target_lpar> <userid>
# Example: ./transfer_package.sh S1234567 PROD1 SYSPROG
#

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/package_transfers"
STAGING_DIR="/tmp/packages"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "${LOG_FILE}"
}

usage() {
    cat << EOF
Usage: $0 <package_id> <target_lpar> <userid>

Arguments:
  package_id   - Shopz order number (e.g., S1234567)
  target_lpar  - Target z/OS LPAR hostname or IP
  userid       - z/OS userid for SFTP connection

Example:
  $0 S1234567 prod1.example.com SYSPROG

Environment Variables (optional):
  STAGING_DIR  - Local staging directory (default: /tmp/packages)
  LOG_DIR      - Log directory (default: /var/log/package_transfers)
EOF
    exit 1
}

# Validate inputs
if [ $# -ne 3 ]; then
    usage
fi

PACKAGE_ID=$1
TARGET_LPAR=$2
USERID=$3

# Setup logging
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/transfer_${PACKAGE_ID}_${TIMESTAMP}.log"

log_info "Starting package transfer process"
log_info "Package: ${PACKAGE_ID}, Target: ${TARGET_LPAR}, User: ${USERID}"

# Find package file
PACKAGE_FILE=$(find "${STAGING_DIR}" -name "${PACKAGE_ID}*" -type f | head -1)

if [ -z "${PACKAGE_FILE}" ]; then
    log_error "Package file not found in ${STAGING_DIR}"
    exit 1
fi

log_info "Found package: ${PACKAGE_FILE}"

# Validate package
log_info "Validating package..."
python3 "${SCRIPT_DIR}/../python/package_validator.py" "${PACKAGE_FILE}"

if [ $? -ne 0 ]; then
    log_error "Package validation failed"
    exit 1
fi

# Calculate checksum
log_info "Calculating MD5 checksum..."
MD5SUM=$(md5sum "${PACKAGE_FILE}" | awk '{print $1}')
log_info "MD5: ${MD5SUM}"

# Target dataset name
TARGET_DATASET="SMPE.PACKAGE.${PACKAGE_ID}"
log_info "Target dataset: ${TARGET_DATASET}"

# Create SFTP batch file
SFTP_BATCH="/tmp/sftp_${PACKAGE_ID}_${TIMESTAMP}.txt"
cat > "${SFTP_BATCH}" << EOF
bin
put ${PACKAGE_FILE} '${TARGET_DATASET}'
quit
EOF

log_info "Transferring package to ${TARGET_LPAR}..."

# Execute SFTP transfer
if sftp -b "${SFTP_BATCH}" "${USERID}@${TARGET_LPAR}" >> "${LOG_FILE}" 2>&1; then
    log_info "✅ Transfer completed successfully"
    
    # Cleanup batch file
    rm -f "${SFTP_BATCH}"
    
    # Generate transfer report
    REPORT_FILE="${LOG_DIR}/report_${PACKAGE_ID}_${TIMESTAMP}.txt"
    cat > "${REPORT_FILE}" << EOF
Package Transfer Report
=======================
Date/Time: $(date)
Package ID: ${PACKAGE_ID}
Source: ${PACKAGE_FILE}
Target LPAR: ${TARGET_LPAR}
Target Dataset: ${TARGET_DATASET}
MD5 Checksum: ${MD5SUM}
Log File: ${LOG_FILE}

Status: SUCCESS
EOF
    
    log_info "Transfer report: ${REPORT_FILE}"
    
    # Optional: Archive source package
    ARCHIVE_DIR="${STAGING_DIR}/archive/$(date +%Y%m%d)"
    mkdir -p "${ARCHIVE_DIR}"
    cp "${PACKAGE_FILE}" "${ARCHIVE_DIR}/"
    log_info "Package archived to ${ARCHIVE_DIR}"
    
else
    log_error "❌ Transfer failed"
    rm -f "${SFTP_BATCH}"
    exit 1
fi

log_info "Package transfer process completed"
exit 0
