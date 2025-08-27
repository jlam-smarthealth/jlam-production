#!/bin/bash
# JLAM Automated Backup Script
# Created: 2025-08-27
# Purpose: Daily automated backups with encryption and off-site storage

set -euo pipefail

# ============================================
# CONFIGURATION
# ============================================
BACKUP_DIR="/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="jlam_backup_${TIMESTAMP}"
RETENTION_DAYS=30
LOG_FILE="/var/log/jlam_backup.log"

# Load environment variables
source /etc/jlam/.env

# ============================================
# LOGGING
# ============================================
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

error_exit() {
    log "ERROR: $1"
    send_alert "Backup Failed" "$1"
    exit 1
}

send_alert() {
    # Send alert via webhook or email
    if [[ -n "${ALERT_WEBHOOK:-}" ]]; then
        curl -X POST "${ALERT_WEBHOOK}" \
            -H 'Content-Type: application/json' \
            -d "{\"text\":\"🚨 JLAM Backup Alert: $1 - $2\"}" || true
    fi
}

# ============================================
# PRE-CHECKS
# ============================================
log "Starting JLAM backup process..."

# Check disk space
AVAILABLE_SPACE=$(df "${BACKUP_DIR}" | awk 'NR==2 {print $4}')
REQUIRED_SPACE=5242880  # 5GB in KB
if [[ ${AVAILABLE_SPACE} -lt ${REQUIRED_SPACE} ]]; then
    error_exit "Insufficient disk space for backup"
fi

# Create backup directory
mkdir -p "${BACKUP_DIR}/${BACKUP_NAME}"
cd "${BACKUP_DIR}/${BACKUP_NAME}"

# ============================================
# DATABASE BACKUPS
# ============================================
log "Backing up PostgreSQL databases..."

# Main JLAM database
PGPASSWORD="${JLAM_DATABASE_PASSWORD}" pg_dump \
    -h "${JLAM_DATABASE_HOST}" \
    -p "${JLAM_DATABASE_PORT}" \
    -U "${JLAM_DATABASE_USER}" \
    -d "${JLAM_DATABASE_NAME}" \
    --no-password \
    --verbose \
    --format=custom \
    --compress=9 \
    --file="jlam_main_${TIMESTAMP}.dump" || error_exit "Main database backup failed"

# Authentik database
PGPASSWORD="${AUTHENTIK_DB_PASSWORD}" pg_dump \
    -h "${AUTHENTIK_DB_HOST}" \
    -p "${AUTHENTIK_DB_PORT}" \
    -U "${AUTHENTIK_DB_USER}" \
    -d "${AUTHENTIK_DB_NAME}" \
    --no-password \
    --verbose \
    --format=custom \
    --compress=9 \
    --file="authentik_${TIMESTAMP}.dump" || error_exit "Authentik database backup failed"

log "Database backups completed successfully"

# ============================================
# DOCKER VOLUMES
# ============================================
log "Backing up Docker volumes..."

# List all volumes with jlam prefix
docker volume ls --format '{{.Name}}' | grep '^jlam' | while read -r volume; do
    log "Backing up volume: ${volume}"
    docker run --rm \
        -v "${volume}:/source:ro" \
        -v "${BACKUP_DIR}/${BACKUP_NAME}:/backup" \
        alpine:latest \
        tar czf "/backup/volume_${volume}_${TIMESTAMP}.tar.gz" -C /source .
done

# ============================================
# CONFIGURATION FILES
# ============================================
log "Backing up configuration files..."

# Create config backup
tar czf "config_${TIMESTAMP}.tar.gz" \
    /etc/jlam/docker-compose.yml \
    /etc/jlam/config/ \
    /etc/jlam/.env.example \
    /etc/nginx/ \
    /etc/ssl/ 2>/dev/null || true

# ============================================
# ENCRYPT BACKUP
# ============================================
log "Encrypting backup..."

# Create archive of all backups
tar czf "../${BACKUP_NAME}.tar.gz" .

# Encrypt with GPG
gpg --batch --yes \
    --passphrase="${BACKUP_ENCRYPTION_KEY}" \
    --cipher-algo AES256 \
    --symmetric \
    --output "../${BACKUP_NAME}.tar.gz.gpg" \
    "../${BACKUP_NAME}.tar.gz" || error_exit "Encryption failed"

# Remove unencrypted archive
rm -f "../${BACKUP_NAME}.tar.gz"

# ============================================
# UPLOAD TO S3
# ============================================
log "Uploading backup to S3..."

aws s3 cp \
    "../${BACKUP_NAME}.tar.gz.gpg" \
    "s3://${BACKUP_S3_BUCKET}/database/${BACKUP_NAME}.tar.gz.gpg" \
    --storage-class GLACIER_IR \
    --server-side-encryption AES256 \
    --metadata "timestamp=${TIMESTAMP},retention=${RETENTION_DAYS}" || error_exit "S3 upload failed"

# ============================================
# CLEANUP
# ============================================
log "Cleaning up old backups..."

# Clean local backups
find "${BACKUP_DIR}" -name "jlam_backup_*.tar.gz.gpg" -mtime +7 -delete

# Clean S3 backups older than retention period
aws s3 ls "s3://${BACKUP_S3_BUCKET}/database/" | while read -r line; do
    FILE_DATE=$(echo "${line}" | awk '{print $1}')
    FILE_NAME=$(echo "${line}" | awk '{print $4}')
    
    if [[ -n "${FILE_NAME}" ]]; then
        FILE_AGE=$(( ($(date +%s) - $(date -d "${FILE_DATE}" +%s)) / 86400 ))
        if [[ ${FILE_AGE} -gt ${RETENTION_DAYS} ]]; then
            log "Deleting old backup: ${FILE_NAME}"
            aws s3 rm "s3://${BACKUP_S3_BUCKET}/database/${FILE_NAME}"
        fi
    fi
done

# Clean temporary files
rm -rf "${BACKUP_DIR}/${BACKUP_NAME}"
rm -f "../${BACKUP_NAME}.tar.gz.gpg"

# ============================================
# VERIFICATION
# ============================================
log "Verifying backup..."

# Check if backup exists in S3
if aws s3 ls "s3://${BACKUP_S3_BUCKET}/database/${BACKUP_NAME}.tar.gz.gpg" > /dev/null 2>&1; then
    log "Backup verified successfully in S3"
    
    # Update metrics for monitoring
    echo "backup_last_success_timestamp $(date +%s)" | curl -X POST \
        --data-binary @- \
        http://localhost:9091/metrics/job/backup_job/instance/production
else
    error_exit "Backup verification failed"
fi

# ============================================
# COMPLETION
# ============================================
BACKUP_SIZE=$(aws s3api head-object \
    --bucket "${BACKUP_S3_BUCKET}" \
    --key "database/${BACKUP_NAME}.tar.gz.gpg" \
    --query 'ContentLength' --output text)

BACKUP_SIZE_MB=$(( BACKUP_SIZE / 1048576 ))

log "Backup completed successfully!"
log "Backup name: ${BACKUP_NAME}"
log "Size: ${BACKUP_SIZE_MB} MB"
log "Location: s3://${BACKUP_S3_BUCKET}/database/${BACKUP_NAME}.tar.gz.gpg"

# Send success notification
send_alert "Backup Successful" "Backup ${BACKUP_NAME} completed (${BACKUP_SIZE_MB} MB)"

exit 0