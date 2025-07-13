# 🖥️ Mimir 워커 노드 (모니터링 대상 노드)

이 디렉토리는 **워커 노드 모니터링 구성**을 포함합니다.

## 📦 포함 서비스

### 📊 모니터링 에이전트
- **Prometheus Agent**: 메트릭 수집 및 중앙 push
- **node-exporter**: 시스템 메트릭 (CPU, 메모리, 디스크, 네트워크)
- **cAdvisor**: 컨테이너 메트릭
- **process-exporter**: 프로세스 모니터링
- **blackbox-exporter**: 외부 서비스 상태 모니터링

### 🗄️ 애플리케이션 서비스
- **MySQL**: 데이터베이스 + mysql-exporter
- **RabbitMQ**: 메시지 브로커 + rabbitmq-exporter
- **Libvirt**: 가상화 모니터링 + libvirt-exporter

## 🚀 실행 방법

### 1. 환경 설정
```bash
# 환경 변수 파일 생성
cp worker-node.env.example worker-node.env

# 설정 편집
vi worker-node.env
```

**필수 설정:**
- `WORKER_NODE_NAME`: 워커 노드 이름 (예: worker-node-1)
- `CENTRAL_MIMIR_URL`: 중앙 노드 URL (예: http://192.168.1.100:9009)

### 2. 실행 (자동화 스크립트)
```bash
# 실행 권한 부여
chmod +x run-worker-node.sh

# 실행
sudo ./run-worker-node.sh
```

### 3. 수동 실행
```bash
# 환경 변수 로드
source worker-node.env

# 실행
docker-compose up -d
```

### 4. 상태 확인
```bash
docker-compose ps
```

### 5. 로그 확인
```bash
docker-compose logs -f prometheus-agent
docker-compose logs -f mysql
```

### 6. 중지
```bash
docker-compose down
```

## 🔗 접근 주소

- **Prometheus Agent**: http://localhost:9090
- **node-exporter**: http://localhost:9100/metrics
- **cAdvisor**: http://localhost:8080/metrics
- **Blackbox Exporter**: http://localhost:9115/metrics
- **MySQL**: localhost:3306 (root/rootpassword)
- **RabbitMQ Management**: http://localhost:15672 (admin/admin123)

## 📊 메트릭 수집

이 워커 노드는 다음 메트릭들을 수집하여 중앙 Mimir로 push합니다:

### 🖥️ 시스템 메트릭
- CPU 사용률, 로드 평균
- 메모리 사용량
- 디스크 사용률 및 I/O
- 네트워크 트래픽

### 🐳 컨테이너 메트릭
- 컨테이너 리소스 사용량
- 컨테이너 상태 및 개수

### 🔍 외부 서비스 모니터링
- HTTP/HTTPS 응답 시간 및 상태
- TCP 포트 연결 상태
- ICMP 핑 응답 시간
- DNS 조회 시간

### 📊 애플리케이션 메트릭
- **MySQL**: 쿼리 성능, 연결 수, 슬로우 쿼리
- **RabbitMQ**: 큐 길이, 메시지 처리량, 연결 수
- **Libvirt**: VM 리소스 사용량, VM 상태

## 🔧 설정 파일

- `config/prometheus.yml`: Prometheus Agent 설정
- `config/blackbox.yml`: 블랙박스 exporter 설정
- `config/process-exporter.yml`: 프로세스 exporter 설정
- `config/mysql-init.sql`: MySQL 초기화 스크립트
- `mysql-exporter/my.cnf`: MySQL exporter 설정

## 🎯 주요 특징

- **Push 방식**: 네트워크 보안 친화적 (아웃바운드만 필요)
- **자동 등록**: 중앙 노드 설정 변경 없이 자동 메트릭 전송
- **완전한 모니터링**: 시스템부터 애플리케이션까지
- **확장성**: 새 워커 노드 추가가 매우 간단
- **헬스체크**: 모든 서비스 상태 자동 확인 