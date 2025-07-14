# 🏗️ Mimir 마스터 노드 (중앙 모니터링 노드)

이 디렉토리는 **중앙 모니터링 인프라**를 포함합니다.

## 📦 포함 서비스

### 🗄️ 핵심 모니터링 인프라
- **Mimir Cluster** (3개 인스턴스): 메트릭 장기 저장소
- **Prometheus**: 중앙 노드 자체 모니터링
- **Grafana**: 통합 대시보드 및 시각화
- **Alertmanager**: 알림 관리

### 🔧 지원 서비스
- **MinIO**: S3 호환 객체 스토리지 (Mimir 백엔드)
- **Nginx Load Balancer**: Mimir 클러스터 로드밸런싱
- **node-exporter**: 중앙 노드 시스템 모니터링
- **cAdvisor**: 중앙 노드 컨테이너 모니터링

## 🚀 실행 방법

### 1. 실행 (자동화 스크립트 권장)
```bash
# 자동화 스크립트 사용
./run-master.sh

# 또는 수동 실행
docker compose up -d
```

### 2. 상태 확인
```bash
docker compose ps
```

### 3. 로그 확인
```bash
docker compose logs -f mimir-1
docker compose logs -f grafana
```

### 4. 중지
```bash
docker compose down
```

## 🔗 접근 주소

- **Grafana**: http://localhost:9000
- **Mimir API**: http://localhost:9009
- **Alertmanager**: http://localhost:9093
- **MinIO Console**: http://localhost:19000

## 📊 워커 노드 연결

워커 노드들은 다음 엔드포인트로 메트릭을 push합니다:
- **Push URL**: `http://[중앙노드IP]:9009/api/v1/push`
- **Tenant ID**: `demo`

## 🎯 주요 특징

- **중앙집중식 저장**: 모든 워커 노드 메트릭이 Mimir에 저장
- **고가용성**: 3개의 Mimir 인스턴스로 클러스터 구성
- **확장성**: 워커 노드 추가 시 중앙 설정 변경 불필요
- **통합 대시보드**: 모든 노드의 메트릭을 하나의 Grafana에서 조회 