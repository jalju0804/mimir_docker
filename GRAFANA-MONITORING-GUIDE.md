# Grafana 모니터링 가이드

## 1. 빠른 시작

### 1.1 시스템 시작
```bash
# Master 노드 시작
cd master
./run-master.sh

# Worker 노드 시작 
cd worker  
./run-worker-node.sh
```

### 1.2 Grafana 접속
- URL: http://localhost:9000
- 로그인: 익명 로그인 활성화 (자동 Admin 권한)

## 2. 데이터소스 설정

현재 4개의 테넌트별 데이터소스가 자동 설정됨:
- **Mimir-Demo** (기본): demo 테넌트
- **Mimir-Production**: prod 테넌트  
- **Mimir-Staging**: staging 테넌트
- **Mimir-Development**: dev 테넌트

## 3. 사전 구성된 대시보드

### 3.1 Master/Mimir 대시보드
- `mimir-overview`: 전체 시스템 개요
- `mimir-writes`: Write path 메트릭 (ingestor, distributor)
- `mimir-reads`: Read path 메트릭 (querier, query-frontend)
- `mimir-queries`: 쿼리 성능 및 latency
- `mimir-tenants`: 테넌트별 메트릭
- `mimir-top-tenants`: 상위 테넌트 리소스 사용량
- `mimir-alertmanager`: Alertmanager 메트릭
- `mimir-ruler`: Rule evaluation 메트릭
- `mimir-compactor`: 데이터 compaction 메트릭
- `mimir-object-store`: MinIO 스토리지 메트릭

### 3.2 커스텀 Worker 대시보드
- `worker-monitoring-dashboard.json` 파일 임포트 사용

## 4. Worker 메트릭 확인

### 4.1 시스템 메트릭
```promql
# Worker 노드 상태
up{job="worker-node-exporter"}

# CPU 사용률
100 - (avg(rate(node_cpu_seconds_total{job="worker-node-exporter",mode="idle"}[5m])) * 100)

# 메모리 사용률  
(1 - (node_memory_MemAvailable_bytes{job="worker-node-exporter"} / node_memory_MemTotal_bytes{job="worker-node-exporter"})) * 100

# 디스크 사용률
100 - ((node_filesystem_avail_bytes{job="worker-node-exporter"} * 100) / node_filesystem_size_bytes{job="worker-node-exporter"})

# 네트워크 트래픽
rate(node_network_receive_bytes_total{job="worker-node-exporter"}[5m])
rate(node_network_transmit_bytes_total{job="worker-node-exporter"}[5m])
```

### 4.2 컨테이너 메트릭
```promql
# 컨테이너 CPU 사용률
rate(container_cpu_usage_seconds_total{job="worker-cadvisor"}[5m])

# 컨테이너 메모리 사용량
container_memory_usage_bytes{job="worker-cadvisor"}

# 컨테이너별 리소스 Top 10
topk(10, rate(container_cpu_usage_seconds_total{job="worker-cadvisor",name!=""}[5m]))
```

### 4.3 애플리케이션 메트릭
```promql
# MySQL 상태
mysql_up{job="worker-mysql-exporter"}
mysql_global_status_connections{job="worker-mysql-exporter"}
mysql_global_status_queries{job="worker-mysql-exporter"}

# RabbitMQ 상태  
rabbitmq_up{job="worker-rabbitmq-exporter"}
rabbitmq_queue_messages_total{job="worker-rabbitmq-exporter"}
rabbitmq_consumers{job="worker-rabbitmq-exporter"}

# Libvirt VM 상태
libvirt_up{job="worker-libvirt-exporter"}
count by (state) (libvirt_domain_state_code{job="worker-libvirt-exporter"})
libvirt_domain_info_cpu_time_seconds_total{job="worker-libvirt-exporter"}
```

### 4.4 블랙박스 모니터링
```promql
# 외부 서비스 상태 체크
probe_success{job="worker-blackbox-exporter"}
probe_duration_seconds{job="worker-blackbox-exporter"}
```

## 5. Master 메트릭 확인

### 5.1 Mimir 컴포넌트 상태
```promql
# 전체 Mimir 컴포넌트 상태
up{job=~"mimir.*"}

# Distributor 메트릭
cortex_distributor_samples_in_total
cortex_distributor_requests_in_total
cortex_distributor_request_duration_seconds

# Ingester 메트릭  
cortex_ingester_samples_appended_total
cortex_ingester_memory_series
cortex_ingester_tsdb_blocks_loaded

# Query Frontend/Querier 메트릭
cortex_query_frontend_queries_total
cortex_querier_request_duration_seconds
cortex_querier_series_fetched
```

### 5.2 스토리지 메트릭
```promql
# MinIO 스토리지 메트릭
minio_cluster_disk_offline_total
minio_cluster_disk_online_total
minio_bucket_usage_object_total
minio_bucket_usage_total_bytes
```

### 5.3 테넌트별 메트릭
```promql
# 테넌트별 ingestion rate
sum(rate(cortex_distributor_samples_in_total[5m])) by (user)

# 테넌트별 series 수
sum(cortex_ingester_memory_series) by (user)

# 테넌트별 쿼리 수
sum(rate(cortex_query_frontend_queries_total[5m])) by (user)
```

## 6. 알림 규칙 예제

### 6.1 Worker 노드 알림
```yaml
# worker/config/alert-rules.yml
groups:
  - name: worker-alerts
    rules:
      - alert: WorkerNodeDown
        expr: up{job="worker-node-exporter"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Worker node is down"
          
      - alert: HighCPUUsage
        expr: 100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          
      - alert: HighMemoryUsage  
        expr: (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
```

## 7. 대시보드 커스터마이징

### 7.1 커스텀 대시보드 생성
1. Grafana → "+" → Dashboard
2. Add Panel → Visualization 선택
3. Query에 PromQL 입력
4. Save Dashboard

### 7.2 기존 대시보드 복제/수정
1. 기존 대시보드 열기
2. Settings (톱니바퀴) → Save As
3. 새 이름으로 저장 후 수정

## 8. 유용한 팁

### 8.1 Variables 사용
```
# 대시보드에서 노드 선택을 위한 Variable
Query: label_values(up{job="worker-node-exporter"}, instance)
Name: worker_node
```

### 8.2 시간 범위 최적화
- 실시간 모니터링: Last 5m, refresh 10s
- 트렌드 분석: Last 24h, refresh 1m  
- 리포팅: Last 7d, refresh 5m

### 8.3 성능 최적화
- 복잡한 쿼리는 recording rule로 사전 계산
- 불필요한 high cardinality 레이블 제거
- 적절한 scrape interval 설정

## 9. 문제 해결

### 9.1 메트릭이 보이지 않는 경우
1. Worker 노드가 올바르게 실행되고 있는지 확인
2. Prometheus target 상태 확인 (Master의 /targets)
3. 네트워크 연결 확인
4. 테넌트 ID 설정 확인

### 9.2 대시보드 로딩이 느린 경우
1. 쿼리 최적화 (시간 범위 축소)
2. Panel 수 줄이기
3. Recording rules 사용

### 9.3 데이터소스 연결 실패
1. Mimir 서비스 상태 확인
2. Nginx 프록시 설정 확인  
3. 테넌트 헤더 설정 확인 