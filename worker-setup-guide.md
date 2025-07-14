# Worker 노드 설정 가이드

이 가이드는 Container 메트릭의 라벨 제한 문제를 해결하기 위한 Worker 노드 설정 방법을 설명합니다.

## 🚨 현재 문제

Worker 노드에서 수집되는 Container 메트릭이 **30개 라벨 제한을 초과**하고 있습니다:
- `container_blkio_device_usage_total`: 40개 라벨
- `container_fs_reads_total`: 37개 라벨  
- `container_tasks_state`: 37개 라벨

## 🔧 해결 방법

### 1. Prometheus 설정 업데이트

Worker 노드의 `prometheus.yml` 파일을 `worker-prometheus-config.yaml` 내용으로 교체:

```bash
# Worker 노드에서 실행
cp worker-prometheus-config.yaml /etc/prometheus/prometheus.yml

# MIMIR_HOST를 Master 노드 IP로 변경
sed -i 's/MIMIR_HOST/YOUR_MASTER_IP/g' /etc/prometheus/prometheus.yml

# Prometheus 재시작
sudo systemctl restart prometheus
```

### 2. cAdvisor 라벨 필터링

cAdvisor에서 직접 라벨을 제한하려면:

```bash
# cAdvisor 실행 시 라벨 화이트리스트 추가
docker run -d \
  --name=cadvisor \
  --restart=unless-stopped \
  --volume=/:/rootfs:ro \
  --volume=/var/run:/var/run:ro \
  --volume=/sys:/sys:ro \
  --volume=/var/lib/docker/:/var/lib/docker:ro \
  --volume=/dev/disk/:/dev/disk:ro \
  --publish=8080:8080 \
  --privileged \
  --device=/dev/kmsg \
  gcr.io/cadvisor/cadvisor:latest \
  --whitelisted_container_labels="name,image,io.kubernetes.container.name,io.kubernetes.pod.name"
```

### 3. 라벨 필터링 확인

적용된 필터링이 작동하는지 확인:

```bash
# 현재 메트릭의 라벨 수 확인
curl -s http://localhost:8080/metrics | grep "container_blkio_device_usage_total" | head -1 | tr ',' '\n' | wc -l

# 30개 이하여야 함
```

## 📊 Master 노드에서 확인

### 1. Mimir 라벨 제한 설정 확인

```bash
# Master 노드에서 실행
grep "max_label_names_per_series" config/mimir.yaml
# 출력: max_label_names_per_series: 100
```

### 2. Runtime 설정 확인

```bash
# Runtime configuration 확인
grep "max_label_names_per_series" config/runtime.yaml
```

### 3. 서비스 재시작 및 확인

```bash
# Master 노드에서 실행
chmod +x fix-mimir-issues.sh
./fix-mimir-issues.sh
```

## 🏷️ 유지할 주요 라벨

Container 메트릭에서 유지해야 할 필수 라벨들:

- `__name__`: 메트릭 이름
- `job`: Prometheus job 이름  
- `instance`: 인스턴스 주소
- `id`: Container ID
- `name`: Container 이름
- `image`: Container 이미지
- `container`: Container 이름 (K8s)
- `pod`: Pod 이름 (K8s)
- `namespace`: Namespace (K8s)
- `cluster`: 클러스터 이름

## 🔍 제거되는 라벨들

다음 라벨들은 자동으로 제거됩니다:

- `container_label_com_docker_compose_*`: Docker Compose 라벨
- `container_label_*_build_*`: Build 관련 라벨
- `container_label_architecture`: Architecture 정보
- `container_label_*_config_hash`: Config hash
- `container_label_*_version`: Version 정보
- `container_label_org_opencontainers_*`: OCI 라벨

## ✅ 검증 방법

### 1. 라벨 수 확인

```bash
# Worker 노드에서 확인
curl -s http://localhost:9090/api/v1/label/__name__/values | jq -r '.data[]' | grep container_ | head -5

# Master 노드에서 확인 (Mimir)
curl -s http://localhost:9009/prometheus/api/v1/label/__name__/values | jq -r '.data[]' | grep container_ | head -5
```

### 2. 메트릭 수집 상태 확인

```bash
# Mimir 로그에서 라벨 제한 오류 확인
docker-compose logs mimir-1 | grep "max-label-names-per-series"
```

### 3. Grafana에서 확인

1. Grafana 접속: http://MASTER_IP:9000
2. Explore → Demo datasource 선택
3. 쿼리: `container_memory_usage_bytes`
4. 메트릭이 정상적으로 표시되는지 확인

## 🚨 주의사항

1. **데이터 손실**: 라벨 필터링으로 일부 메타데이터가 제거됩니다
2. **호환성**: 기존 대시보드에서 제거된 라벨을 사용하는 경우 수정이 필요합니다
3. **모니터링**: 정기적으로 라벨 수를 모니터링하여 제한을 초과하지 않도록 해야 합니다

## 📞 문제 해결

라벨 제한 문제가 계속 발생하는 경우:

1. Runtime configuration 재확인
2. Prometheus relabeling 규칙 검증
3. cAdvisor 재시작
4. Mimir 로그 분석

```bash
# 상세 로그 확인
docker-compose logs -f mimir-1 | grep -E "(label|push|error)"
``` 