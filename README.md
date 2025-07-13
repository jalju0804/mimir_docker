# 📊 Mimir Push 기반 모니터링 시스템

이 프로젝트는 **Grafana Mimir**를 사용한 **Push 기반 중앙집중식 모니터링 시스템**입니다.

## 🏗️ 시스템 구조

```
┌─────────────────────────────────────┐    ┌─────────────────────────────────────┐
│        마스터 노드 (중앙 모니터링)      │    │            워커 노드                  │
│                                    │    │                                   │
│  ┌─────────────────────────────────┐│    │ ┌─────────────────────────────────┐ │
│  │ 🗄️  Mimir Cluster (3 nodes)     ││◄───┤ │ 📊 Prometheus Agent             │ │
│  │   :9009/api/v1/push             ││    │ │  - 로컬 메트릭 수집 & push       │ │
│  └─────────────────────────────────┘│    │ └─────────────────────────────────┘ │
│                                    │    │                                   │
│  ┌─────────────────────────────────┐│    │ ┌─────────────────────────────────┐ │
│  │ 📈 Grafana (통합 대시보드)        ││    │ │ 📊 Monitoring & Services        │ │
│  └─────────────────────────────────┘│    │ │ • System (node-exporter)       │ │
│                                    │    │ │ • Containers (cadvisor)        │ │
│  ┌─────────────────────────────────┐│    │ │ • Processes (process-exporter) │ │
│  │ 🗄️  MinIO (객체 스토리지)         ││    │ │ • External (blackbox-exporter) │ │
│  └─────────────────────────────────┘│    │ │ • MySQL + RabbitMQ + Libvirt   │ │
└─────────────────────────────────────┘    │ └─────────────────────────────────┘ │
                                          └─────────────────────────────────────┘
```

## 📁 폴더 구조

```
mimir/
├── master/                    # 🏗️ 마스터 노드 (중앙 모니터링)
│   ├── docker-compose.yml     # 중앙 모니터링 인프라
│   ├── config/                # 마스터 노드 설정
│   │   ├── prometheus.yaml    # 중앙 노드 자체 모니터링
│   │   ├── mimir.yaml         # Mimir 클러스터 설정
│   │   ├── nginx.conf         # 로드밸런서 설정
│   │   └── 기타 설정들...
│   ├── mimir-mixin-compiled/  # Mimir 대시보드 & 알림 룰
│   └── README.md              # 마스터 노드 사용법
│
├── worker/                    # 🖥️ 워커 노드 (모니터링 대상)
│   ├── docker-compose.yml     # 워커 노드 모니터링 스택
│   ├── config/                # 워커 노드 설정
│   │   ├── prometheus.yml     # Prometheus Agent 설정
│   │   ├── blackbox.yml       # 블랙박스 exporter 설정
│   │   ├── process-exporter.yml
│   │   └── mysql-init.sql
│   ├── mysql-exporter/        # MySQL exporter 설정
│   ├── worker-node.env.example # 환경 변수 예시
│   ├── run-worker-node.sh     # 실행 스크립트
│   └── README.md              # 워커 노드 사용법
│
└── README.md                  # 이 파일
```

## 🚀 빠른 시작

### 1. 마스터 노드 실행
```bash
cd master
docker-compose up -d
```

### 2. 워커 노드 실행
```bash
cd worker

# 환경 설정
cp worker-node.env.example worker-node.env
vi worker-node.env  # WORKER_NODE_NAME, CENTRAL_MIMIR_URL 설정

# 실행
chmod +x run-worker-node.sh
sudo ./run-worker-node.sh
```

### 3. 모니터링 확인
- **Grafana**: http://localhost:9000
- **Mimir API**: http://localhost:9009
- **워커 노드 메트릭**: http://localhost:9090 (Prometheus Agent)

## 🎯 주요 특징

### 🔐 Push 기반 보안
- **아웃바운드 전용**: 워커 노드는 중앙으로만 연결
- **인바운드 불필요**: 워커 노드에 외부 접근 포트 불필요
- **방화벽 친화적**: 대부분의 기업 환경에서 허용

### 📈 확장성
- **새 워커 노드 추가**: 환경 변수 설정 후 실행만
- **중앙 설정 불필요**: 새 노드 추가 시 마스터 설정 변경 없음
- **자동 등록**: 워커 노드가 자동으로 메트릭 전송 시작

### 🔍 완전한 모니터링
- **시스템 메트릭**: CPU, 메모리, 디스크, 네트워크
- **컨테이너 메트릭**: 리소스 사용량, 상태
- **애플리케이션 메트릭**: MySQL, RabbitMQ, Libvirt
- **외부 서비스 모니터링**: HTTP/HTTPS, TCP, ICMP, DNS

## 📊 메트릭 수집 흐름

1. **워커 노드**: 각자 Prometheus Agent로 로컬 메트릭 수집
2. **중앙 Push**: 모든 워커 노드 → Mimir (`/api/v1/push`)
3. **통합 저장**: 모든 메트릭이 Mimir에 중앙 저장
4. **시각화**: Grafana에서 모든 노드 데이터 통합 조회

## 🔧 설정 가이드

### 워커 노드 환경 변수
```bash
# 필수 설정
WORKER_NODE_NAME=worker-node-1              # 워커 노드 이름
CENTRAL_MIMIR_URL=http://192.168.1.100:9009 # 마스터 노드 URL

# 선택 설정
SCRAPE_INTERVAL=15s                         # 메트릭 수집 주기
PROMETHEUS_RETENTION=2h                     # 로컬 저장 기간
LOG_LEVEL=warn                              # 로그 레벨
```

### 네트워크 요구사항
- **워커 → 마스터**: 9009 포트 (Mimir push 엔드포인트)
- **관리자 → 마스터**: 9000 포트 (Grafana 웹 UI)
- **관리자 → 워커**: 9090 포트 (Prometheus Agent, 선택사항)

## 💡 사용 케이스

### 🏢 기업 환경
- **데이터센터**: 여러 서버 중앙 모니터링
- **클라우드**: 분산된 인스턴스 통합 모니터링
- **하이브리드**: 온프레미스 + 클라우드 혼합 환경

### 🐳 컨테이너 환경
- **Docker**: 컨테이너 리소스 모니터링
- **Kubernetes**: 노드 및 파드 메트릭 수집
- **OpenStack**: 가상화 인프라 모니터링

### 🔧 애플리케이션 모니터링
- **데이터베이스**: MySQL, PostgreSQL 성능 모니터링
- **메시지 큐**: RabbitMQ, Kafka 상태 모니터링
- **웹 서비스**: API 응답 시간, 가용성 모니터링

## 🛠️ 개발 & 기여

각 폴더의 README.md에서 세부 사용법을 확인하세요:
- [마스터 노드 가이드](master/README.md)
- [워커 노드 가이드](worker/README.md)

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.
