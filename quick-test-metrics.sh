#!/bin/bash

# 빠른 테스트 메트릭 전송 스크립트
# Usage: ./quick-test-metrics.sh [SERVER_IP] [TENANT_ID]

SERVER_IP=${1:-"localhost"}
TENANT_ID=${2:-"demo"}
MIMIR_URL="http://$SERVER_IP:9009"

echo "📊 Mimir 테스트 메트릭 전송 중..."
echo "Server: $SERVER_IP"
echo "URL: $MIMIR_URL"
echo "Tenant: $TENANT_ID"
echo ""

# 현재 시간
TIMESTAMP=$(date +%s)

# 테스트 메트릭 전송 (간단한 형식)
response=$(curl -s -w "%{http_code}" -X POST \
  -H "Content-Type: application/x-protobuf" \
  -H "X-Scope-OrgID: $TENANT_ID" \
  -H "X-Prometheus-Remote-Write-Version: 0.1.0" \
  --data-raw "# TYPE test_metric gauge
test_cpu_usage{instance=\"test-node\",job=\"manual-test\"} 45.6 $TIMESTAMP
test_memory_usage{instance=\"test-node\",job=\"manual-test\"} 67.8 $TIMESTAMP
test_disk_usage{instance=\"test-node\",job=\"manual-test\"} 23.4 $TIMESTAMP
test_requests_total{method=\"GET\",status=\"200\"} 1234 $TIMESTAMP
test_active_users 89 $TIMESTAMP" \
  "$MIMIR_URL/api/v1/push")

echo "HTTP Response: $response"

if [[ "$response" == "200" || "$response" == "204" ]]; then
    echo "✅ 메트릭 전송 성공!"
else
    echo "❌ 메트릭 전송 실패 (HTTP $response)"
fi

echo ""
echo "🔍 Grafana에서 확인하세요:"
echo "1. http://$SERVER_IP:9000 으로 접속"
echo "2. Explore 탭 클릭"
echo "3. 데이터소스: Mimir-Demo 선택"
echo "4. 메트릭 쿼리:"
echo "   test_cpu_usage"
echo "   test_memory_usage"
echo "   test_requests_total"
echo "   test_active_users"
echo ""
echo "📈 시계열 차트용 쿼리:"
echo "   rate(test_requests_total[5m])"
echo "   avg_over_time(test_cpu_usage[10m])" 