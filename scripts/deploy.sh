#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f ".env" ]]; then
  echo "[ERROR] .env 파일이 없습니다. .env.example을 복사해 .env를 생성하세요."
  exit 1
fi

docker compose pull
docker compose up -d
docker compose ps

echo "[OK] deployment completed"