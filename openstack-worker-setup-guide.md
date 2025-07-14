# OpenStack 워커 노드 설정 가이드

## 개요
이미 실행 중인 OpenStack Kolla 환경의 exporter들을 활용하여 Mimir의 openstack 테넌트로 메트릭을 전송하는 워커 Prometheus를 설정합니다.

## 전제 조건
- OpenStack Kolla 환경이 이미 실행 중
- 다음 exporter들이 실행 중이어야 함:
  - prometheus_node_exporter
  - prometheus_cadvisor  
  - prometheus_mysqld_exporter
  - prometheus_memcached_exporter
  - prometheus_openstack_exporter
  - prometheus_blackbox_exporter
  - prometheus_server

## 설정 단계

### 1. 설정 파일 준비
OpenStack 노드에서 작업 디렉토리를 생성하고 설정 파일들을 복사합니다:

```bash
# 작업 디렉토리 생성
mkdir -p /opt/mimir-worker
cd /opt/mimir-worker

# Mimir 마스터에서 설정 파일들 복사
scp user@mimir-master:/path/to/openstack-worker-prometheus.yml ./
scp user@mimir-master:/path/to/openstack-worker-docker-compose.yml ./docker-compose.yml
```

### 2. Mimir 마스터 IP 설정
`openstack-worker-prometheus.yml` 파일에서 Mimir 마스터 IP를 실제 IP로 변경:

```yaml
remote_write:
  - url: http://[실제_Mimir_마스터_IP]:9009/api/v1/push
```

### 3. 포트 확인 및 조정
기존 exporter들의 실제 포트를 확인하고 필요시 조정:

```bash
# 실행 중인 exporter 포트 확인
sudo docker ps --format "table {{.Names}}\t{{.Ports}}" | grep prometheus

# 필요시 openstack-worker-prometheus.yml의 타겟 포트 수정
```

### 4. 워커 Prometheus 실행

```bash
cd /opt/mimir-worker

# 워커 Prometheus 시작
docker-compose up -d

# 로그 확인
docker-compose logs -f openstack-worker-prometheus
```

### 5. 연결 확인

```bash
# 워커 Prometheus 웹 UI 접속
# http://[OpenStack_노드_IP]:9091

# 타겟 상태 확인
curl http://localhost:9091/api/v1/targets

# 메트릭 수집 확인
curl http://localhost:9091/api/v1/query?query=up
```

## 문제 해결

### 1. Exporter 연결 실패
```bash
# 각 exporter 상태 개별 확인
curl http://localhost:9100/metrics  # node-exporter
curl http://localhost:8080/metrics  # cadvisor
curl http://localhost:9104/metrics  # mysql-exporter
curl http://localhost:9150/metrics  # memcached-exporter
curl http://localhost:9180/metrics  # openstack-exporter
curl http://localhost:9115/metrics  # blackbox-exporter
```

### 2. 네트워크 문제
- Docker 컨테이너가 host 네트워크를 사용하는지 확인
- 방화벽 설정 확인 (포트 9091)

### 3. Mimir 연결 문제
```bash
# Mimir 마스터 연결 테스트
curl -X POST http://[Mimir_마스터_IP]:9009/api/v1/push \
  -H "Content-Type: application/x-protobuf" \
  -H "X-Scope-OrgID: openstack" \
  --data-binary @test-data
```

## 모니터링 확인

### Grafana에서 확인
1. Grafana 접속: http://[Mimir_마스터_IP]:3000
2. Mimir-OpenStack 데이터소스 선택
3. 다음 쿼리로 데이터 확인:
   ```promql
   up{cluster="openstack"}
   node_cpu_seconds_total{cluster="openstack"}
   container_memory_usage_bytes{cluster="openstack"}
   mysql_up{cluster="openstack"}
   openstack_nova_instances{cluster="openstack"}
   ```

### 주요 메트릭 확인 목록
- **시스템 메트릭**: `node_*` (CPU, 메모리, 디스크, 네트워크)
- **컨테이너 메트릭**: `container_*` (OpenStack 서비스 컨테이너들)
- **MySQL 메트릭**: `mysql_*` (MariaDB 상태)
- **Memcached 메트릭**: `memcached_*` (캐시 상태)
- **OpenStack 서비스**: `openstack_*` (Nova, Neutron 등)
- **연결성 체크**: Blackbox exporter 메트릭

## 유지보수

### 설정 변경 시
```bash
# 설정 파일 수정 후 재로드
docker-compose exec openstack-worker-prometheus \
  curl -X POST http://localhost:9091/-/reload
```

### 업그레이드 시
```bash
# 이미지 업데이트
docker-compose pull
docker-compose up -d
```

### 로그 모니터링
```bash
# 실시간 로그 확인
docker-compose logs -f

# 특정 시간 로그 확인
docker-compose logs --since="1h" openstack-worker-prometheus
```

## 성능 최적화

### 메트릭 필터링
불필요한 메트릭을 제거하여 성능 향상:

1. `openstack-worker-prometheus.yml`에서 `metric_relabel_configs` 추가
2. 고카디널리티 메트릭 제거
3. 라벨 정리

### 스크래핑 간격 조정
리소스 사용량에 따라 `scrape_interval` 조정:
- 중요 서비스: 15-30초
- 일반 메트릭: 60초
- 상태 체크: 30초 