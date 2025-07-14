# Worker 노드 빠른 설정 가이드

## 🚀 즉시 테스트하기

다른 서버에서 Master 노드가 실행 중이라면:

### 1. 테스트 메트릭 전송 (어디서든 실행 가능)
```bash
# 서버 IP를 실제 Master 서버 IP로 변경하세요
chmod +x quick-test-metrics.sh
./quick-test-metrics.sh [MASTER_SERVER_IP]

# 예시:
./quick-test-metrics.sh 192.168.1.100
```

### 2. Worker 노드 설정 (필요시)

Worker 디렉토리로 이동:
```bash
cd ../worker
```

환경 파일 생성:
```bash
cp worker-node.env.example worker-node.env
```

환경 파일 수정:
```bash
# worker-node.env 파일에서 다음 값들 수정:
WORKER_NODE_NAME=worker-node-1
CENTRAL_MIMIR_URL=http://[MASTER_SERVER_IP]:9009
TENANT_ID=demo
```

Worker 노드 실행:
```bash
./run-worker-node.sh
```

## 📊 Grafana에서 확인하기

1. **Grafana 접속**: http://[MASTER_SERVER_IP]:9000
2. **Explore 탭** 클릭
3. **데이터소스 선택**: Mimir-Demo
4. **메트릭 쿼리 테스트**:
   ```promql
   # 테스트 메트릭
   test_cpu_usage
   test_memory_usage
   test_requests_total
   
   # 실제 시스템 메트릭 (Worker 노드 실행 후)
   up
   node_cpu_seconds_total
   node_memory_MemTotal_bytes
   ```

## 🔧 문제 해결

### 데이터가 안 보이는 경우:
1. Master 서비스 상태 확인
2. 테스트 메트릭 전송 시도
3. 데이터소스 연결 테스트
4. Worker 노드 로그 확인

### 즉시 확인 가능한 메트릭:
- `test_cpu_usage`: CPU 사용률 테스트
- `test_memory_usage`: 메모리 사용률 테스트  
- `test_requests_total`: 요청 수 테스트
- `test_active_users`: 활성 사용자 수 테스트

### 차트 생성용 쿼리:
```promql
rate(test_requests_total[5m])
avg_over_time(test_cpu_usage[10m])
increase(test_requests_total[1h])
``` 