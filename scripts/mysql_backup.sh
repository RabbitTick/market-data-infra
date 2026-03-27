#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f ".env" ]]; then
  echo "[ERROR] .env 파일이 없습니다."
  exit 1
fi

set -a
source ".env"
set +a

BACKUP_DIR="${ROOT_DIR}/backups/mysql"
RETAIN_DAYS="${BACKUP_RETAIN_DAYS:-7}"
mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
OUTPUT_FILE="${BACKUP_DIR}/rabbittick_${TIMESTAMP}.sql.gz"
TMP_FILE="${OUTPUT_FILE}.tmp"

if ! docker exec rabbittick-mysql sh -c \
  "mysqldump -uroot -p${MYSQL_ROOT_PASSWORD} --single-transaction --routines --triggers ${MYSQL_DATABASE}" \
  | gzip > "$TMP_FILE"; then
  rm -f "$TMP_FILE"
  echo "[ERROR] mysqldump 실패. 백업이 생성되지 않았습니다."
  exit 1
fi

if [[ ! -s "$TMP_FILE" ]]; then
  rm -f "$TMP_FILE"
  echo "[ERROR] 백업 파일이 비어 있습니다."
  exit 1
fi

mv "$TMP_FILE" "$OUTPUT_FILE"
echo "[OK] backup created: $OUTPUT_FILE ($(du -sh "$OUTPUT_FILE" | cut -f1))"

find "$BACKUP_DIR" -name "rabbittick_*.sql.gz" -mtime +"$RETAIN_DAYS" -delete
echo "[OK] backups older than ${RETAIN_DAYS} days removed"