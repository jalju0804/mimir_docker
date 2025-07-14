#!/bin/bash

# 테스트 메트릭을 Mimir로 전송하는 스크립트
MIMIR_URL=${1:-"http://localhost:9009"}
TENANT_ID=${2:-"demo"}

echo "📊 Mimir에 테스트 메트릭 전송 중..."
echo "URL: $MIMIR_URL"
echo "Tenant: $TENANT_ID"

# 현재 시간 (밀리초)
TIMESTAMP=$(date +%s%3N)

# Prometheus 형식으로 테스트 메트릭 전송
curl -X POST \
  -H "Content-Type: text/plain" \
  -H "X-Scope-OrgID: $TENANT_ID" \
  --data-raw "
test_cpu_usage{instance=\"test-server\",job=\"test\"} 45.2 $TIMESTAMP
test_memory_usage{instance=\"test-server\",job=\"test\"} 68.5 $TIMESTAMP
test_requests_total{method=\"GET\",status=\"200\"} 150 $TIMESTAMP
test_active_users 125 $TIMESTAMP
" \
  "$MIMIR_URL/api/v1/push"

echo "✅ 테스트 메트릭 전송 완료!" 