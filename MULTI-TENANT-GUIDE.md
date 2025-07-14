# 🏢 Mimir 다중 테넌시 가이드

Mimir의 다중 테넌시 기능을 활용하여 환경별/프로젝트별로 메트릭을 분리 관리하는 방법을 안내합니다.

## 📋 개요

### 🎯 다중 테넌시란?
- **테넌트**: 독립적인 메트릭 네임스페이스 (예: 프로덕션, 스테이징, 개발환경)
- **분리**: 각 테넌트의 데이터는 완전히 분리되어 저장/조회
- **보안**: 테넌트별 접근 제어 및 리소스 제한 가능

### 🔧 현재 설정된 테넌트들
- **demo**: 기본 테스트 환경 (14일 보존)
- **prod**: 프로덕션 환경 (90일 보존, 높은 성능)
- **staging**: 스테이징 환경 (7일 보존, 중간 성능)
- **dev**: 개발 환경 (3일 보존, 낮은 성능)

## 🚀 워커 노드별 테넌트 설정

### 1️⃣ 환경별 워커 노드 구성

#### 프로덕션 환경
```bash
# worker-node.env 설정
WORKER_NODE_NAME=prod-worker-1
CENTRAL_MIMIR_URL=http://192.168.1.100:9009
TENANT_ID=prod
```

#### 스테이징 환경
```bash
# worker-node.env 설정
WORKER_NODE_NAME=staging-worker-1
CENTRAL_MIMIR_URL=http://192.168.1.100:9009
TENANT_ID=staging
```

#### 개발 환경
```bash
# worker-node.env 설정
WORKER_NODE_NAME=dev-worker-1
CENTRAL_MIMIR_URL=http://192.168.1.100:9009
TENANT_ID=dev
```

### 2️⃣ 여러 워커 노드 실행 예시
```bash
# 프로덕션 워커 노드 1
mkdir -p /opt/monitoring/prod-worker-1
cd /opt/monitoring/prod-worker-1
cp -r /path/to/worker/* .
echo "TENANT_ID=prod" >> worker-node.env
echo "WORKER_NODE_NAME=prod-worker-1" >> worker-node.env
./run-worker-node.sh

# 스테이징 워커 노드 1
mkdir -p /opt/monitoring/staging-worker-1
cd /opt/monitoring/staging-worker-1
cp -r /path/to/worker/* .
echo "TENANT_ID=staging" >> worker-node.env
echo "WORKER_NODE_NAME=staging-worker-1" >> worker-node.env
./run-worker-node.sh
```

## 📊 Grafana에서 테넌트별 모니터링

### 🔍 데이터소스 선택
Grafana에서 다음 데이터소스들을 선택하여 테넌트별 데이터 조회:

- **Mimir-Demo**: 데모/테스트 환경 메트릭
- **Mimir-Production**: 프로덕션 환경 메트릭
- **Mimir-Staging**: 스테이징 환경 메트릭
- **Mimir-Development**: 개발 환경 메트릭
- **Mimir-All-Tenants**: 전체 테넌트 통합 뷰 (관리자용)

### 📈 대시보드 생성 팁
```promql
# 특정 테넌트의 메트릭 조회 (데이터소스에서 자동 필터링됨)
up{job="worker-node-exporter"}

# 테넌트별 비교 대시보드를 만들 때
# 여러 데이터소스를 하나의 패널에서 사용 가능
```

## ⚙️ 테넌트별 리소스 제한

### 📏 현재 설정된 제한사항

| 테넌트 | 초당 샘플 수 | 최대 시리즈 수 | 보존 기간 | 용도 |
|--------|-------------|--------------|-----------|------|
| prod   | 20,000      | 10,000,000   | 90일      | 프로덕션 |
| staging| 5,000       | 1,000,000    | 7일       | 스테이징 |
| dev    | 1,000       | 100,000      | 3일       | 개발 |
| demo   | 10,000      | 2,000,000    | 14일      | 데모/테스트 |

### 🔧 제한사항 수정
`master/config/mimir.yaml`의 `overrides` 섹션에서 테넌트별 설정 수정:

```yaml
overrides:
  your_new_tenant:
    ingestion_rate: 15000                    # 초당 샘플 수
    max_series_per_user: 3000000            # 최대 시리즈 수
    compactor_blocks_retention_period: 60d   # 보존 기간
```

## 🔐 보안 및 접근 제어

### 🔑 현재 인증 방식
- **헤더 기반**: `X-Scope-OrgID` 헤더로 테넌트 구분
- **간단한 설정**: 별도 인증 서버 없이 사용 가능

### 🛡️ 프로덕션 환경 보안 강화
```yaml
# master/config/mimir.yaml에 추가
auth_enabled: true

# 인증 토큰 기반으로 업그레이드 가능
# JWT, Basic Auth, 또는 외부 인증 시스템 연동
```

## 📊 모니터링 및 관리

### 🎯 테넌트별 메트릭 확인
```bash
# 특정 테넌트의 메트릭 수 확인
curl -H "X-Scope-OrgID: prod" \
  http://localhost:9009/prometheus/api/v1/label/__name__/values

# 테넌트별 시리즈 수 확인
curl -H "X-Scope-OrgID: prod" \
  http://localhost:9009/prometheus/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes
```

### 📈 테넌트 사용량 모니터링
Mimir는 테넌트별 사용량 메트릭을 제공합니다:
- `cortex_ingester_active_series{user="prod"}`: 활성 시리즈 수
- `cortex_distributor_samples_in_total{user="prod"}`: 수집된 총 샘플 수
- `cortex_query_frontend_queries_total{user="prod"}`: 쿼리 수

## 🚀 새 테넌트 추가 방법

### 1️⃣ Mimir 설정 업데이트
```yaml
# master/config/mimir.yaml에 추가
overrides:
  new_tenant:
    ingestion_rate: 5000
    max_series_per_user: 1000000
    compactor_blocks_retention_period: 30d
```

### 2️⃣ Grafana 데이터소스 추가
```yaml
# master/config/grafana-provisioning-datasources.yaml에 추가
- name: Mimir-NewTenant
  type: prometheus
  access: proxy
  orgId: 1
  url: http://nginx:8080/prometheus
  httpHeaderName1: "X-Scope-OrgID"
  httpHeaderValue1: "new_tenant"
```

### 3️⃣ 워커 노드 설정
```bash
# 새 워커 노드의 worker-node.env
TENANT_ID=new_tenant
WORKER_NODE_NAME=new-tenant-worker-1
```

### 4️⃣ 재시작
```bash
# 마스터 노드 재시작
cd master && docker compose restart

# 새 워커 노드 시작
cd worker && ./run-worker-node.sh
```

## ❗ 주의사항

1. **테넌트 삭제**: 한번 생성된 테넌트 데이터는 보존 기간 후 자동 삭제
2. **리소스 모니터링**: 테넌트별 리소스 사용량을 주기적으로 확인
3. **백업**: 중요한 테넌트는 별도 백업 전략 수립
4. **네이밍**: 테넌트 이름은 변경 불가능하므로 신중하게 선택
5. **권한**: 프로덕션 환경에서는 테넌트별 접근 권한 관리 필수

## 🔗 관련 링크

- [Mimir 공식 문서](https://grafana.com/docs/mimir/)
- [Grafana 다중 테넌시](https://grafana.com/docs/grafana/latest/administration/multi-tenancy/)
- [Prometheus Remote Write](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write) 