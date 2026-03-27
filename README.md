# market-data-infra

`market-ingest-streamer`와 `market-data-persister`를 OCI Always Free 환경에서 함께 운영하기 위한 배포 전용 인프라 레포입니다.

## 레포 구성
```
market-data-infra/
├── docker-compose.yml
├── .env.example
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   └── grafana/
│       └── provisioning/
│           └── datasources/
│               └── datasource.yml
└── scripts/
    ├── deploy.sh
    └── mysql_backup.sh
```

## 빠른 시작

**1. 환경 파일 준비**
```bash
cp .env.example .env
vi .env  # INGEST_IMAGE, PERSISTER_IMAGE에 SHA 태그 입력
```

**2. 배포 실행**
```bash
bash scripts/deploy.sh
```

**3. 접속 확인**

| 서비스 | 주소 |
|---|---|
| Grafana | `http://<VM_IP>:3000` |
| Prometheus | `http://<VM_IP>:9090` |
| RabbitMQ UI | `http://<VM_IP>:15672` |

## 롤백 절차

**1. 이전 SHA 확인** — GitHub Actions 실행 이력에서 확인

**2. .env 수정**
```bash
vi .env
# INGEST_IMAGE=ghcr.io/rabbittick/market-ingest-streamer:<이전SHA>
# PERSISTER_IMAGE=ghcr.io/rabbittick/market-data-persister:<이전SHA>
```

**3. 재배포**
```bash
bash scripts/deploy.sh
```

## 백업 및 복구

**수동 백업**
```bash
bash scripts/mysql_backup.sh
```

**cron 등록 (매일 새벽 3시)**
```bash
crontab -e
# 0 3 * * * cd /path/to/market-data-infra && bash scripts/mysql_backup.sh >> /var/log/mysql_backup.log 2>&1
```

**복구 검증 (최초 배포 후 1회 필수)**
```bash
# 테스트 컨테이너 기동
docker run --rm -d --name mysql-restore-test \
  -e MYSQL_ROOT_PASSWORD=testpass mysql:8.0
sleep 10

# 복구
gunzip -c backups/mysql/rabbittick_<TIMESTAMP>.sql.gz \
  | docker exec -i mysql-restore-test mysql -uroot -ptestpass

# 확인
docker exec mysql-restore-test mysql -uroot -ptestpass \
  -e "SELECT table_name, table_rows FROM information_schema.tables WHERE table_schema='rabbittick';"

# 삭제
docker rm -f mysql-restore-test
```

## 운영 참고

- 이미지 태그 `latest` 사용 금지 — 반드시 git SHA 태그 사용
- Grafana 대시보드 변경 후 JSON export로 레포에 커밋해 버전 관리
- Always Free 자원 부족 시 분리 순서: Grafana/Prometheus → MySQL