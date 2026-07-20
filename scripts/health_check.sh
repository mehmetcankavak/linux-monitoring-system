# Health check script - v1.1
#!/bin/bash
set -euo pipefail
# Varsayılan eşik değeri (disk kullanımı için, yüzde olarak)
THRESHOLD=85
LOG_FILE="/var/log/health_alerts.log"
while getopts "t:" opt; do
  case $opt in
    t) THRESHOLD="$OPTARG" ;;
    \?) echo "Kullanım: $0 [-t esik_yuzdesi]" >&2; exit 1 ;;
  esac
done
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

cleanup() {
    log "Health check tamamlandı, çıkılıyor."
}
trap cleanup EXIT
log "Health check başlatılıyor... (eşik: %${THRESHOLD})"

# Disk kullanımı (kök dizin /)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# RAM kullanımı (yüzde olarak)
MEM_USAGE=$(free | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')

# CPU kullanımı (basit yöntem: 1 dakikalık load average)
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | tr -d ' ')

log "Disk kullanımı: %${DISK_USAGE}"
log "RAM kullanımı: %${MEM_USAGE}"
log "CPU load (1 dk ortalama): ${CPU_LOAD}"

if [ "$DISK_USAGE" -gt "$THRESHOLD" ]; then
    log "UYARI: Disk kullanımı eşiği aştı! (%${DISK_USAGE} > %${THRESHOLD})"
    ALERT=true
else
    log "Disk kullanımı normal seviyede."
    ALERT=false
fi

if [ "$MEM_USAGE" -gt "$THRESHOLD" ]; then
    log "UYARI: RAM kullanımı eşiği aştı! (%${MEM_USAGE} > %${THRESHOLD})"
    ALERT=true
fi

if [ "$ALERT" = true ]; then
    log "Sonuç: En az bir kaynak kritik seviyede."
    exit 1
else
    log "Sonuç: Sistem sağlıklı."
    exit 0
fi
