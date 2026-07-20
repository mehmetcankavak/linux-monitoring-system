#!/bin/bash
set -euo pipefail

SOURCE_DIR="/home/devopsuser"
BACKUP_DIR="/home/devopsuser/backups"
RETENTION_DAYS=7
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/backup_${DATE}.tar.gz"
LOG_FILE="/var/log/backup.log"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

mkdir -p "$BACKUP_DIR"

log "Yedekleme başlatılıyor: ${SOURCE_DIR}"

if tar -czf "$BACKUP_FILE" \
    --exclude="${BACKUP_DIR#/}" \
    -C / "${SOURCE_DIR#/}" 2>>"$LOG_FILE"; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log "Yedekleme başarılı: ${BACKUP_FILE} (boyut: ${BACKUP_SIZE})"
else
    log "HATA: Yedekleme başarısız oldu!"
    exit 1
fi

log "Yedekler taranıyor, ${RETENTION_DAYS} günden eski olanlar temizlenecek..."

DELETED_COUNT=$(find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime "+${RETENTION_DAYS}" | wc -l)

find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete

log "${DELETED_COUNT} adet eski yedek silindi."

# Log rotasyonu
if [ -f "$LOG_FILE" ]; then
    LOG_SIZE=$(du -m "$LOG_FILE" | cut -f1)
    if [ "$LOG_SIZE" -gt 50 ]; then
        mv "$LOG_FILE" "${LOG_FILE}.old"
        gzip "${LOG_FILE}.old"
    fi
fi
