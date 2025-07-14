#!/bin/bash

# Grafana 데이터소스 연결 디버깅 스크립트
SERVER_IP=${1:-"localhost"}
TENANT_ID=${2:-"demo"}

echo "🔍 Mimir 데이터소스 연결 디버깅"
echo "서버: $SERVER_IP"
echo "테넌트: $TENANT_ID"
echo ""

# 1. Mimir 직접 연결 테스트 (멀티테넌시 활성화)
echo "1️⃣ Mimir 직접 연결 테스트 (with tenant)"
response1=$(curl -s -w "%{http_code}" -X GET \
  -H "X-Scope-OrgID: $TENANT_ID" \
  "http://$SERVER_IP:9009/api/v1/label/__name__/values" \
  -o /tmp/mimir_response1.json)

echo "HTTP Response: $response1"
if [[ "$response1" == "200" ]]; then
    echo "✅ 멀티테넌트 연결 성공"
    echo "메트릭 리스트:"
    cat /tmp/mimir_response1.json | head -5
else
    echo "❌ 멀티테넌트 연결 실패"
fi
echo ""

# 2. Mimir 직접 연결 테스트 (멀티테넌시 없이)
echo "2️⃣ Mimir 직접 연결 테스트 (without tenant)"
response2=$(curl -s -w "%{http_code}" -X GET \
  "http://$SERVER_IP:9009/api/v1/label/__name__/values" \
  -o /tmp/mimir_response2.json)

echo "HTTP Response: $response2"
if [[ "$response2" == "200" ]]; then
    echo "✅ 비-멀티테넌트 연결 성공"
    echo "메트릭 리스트:"
    cat /tmp/mimir_response2.json | head -5
else
    echo "❌ 비-멀티테넌트 연결 실패"
fi
echo ""

# 3. Load Balancer 연결 테스트
echo "3️⃣ Load Balancer 연결 테스트"
response3=$(curl -s -w "%{http_code}" -X GET \
  -H "X-Scope-OrgID: $TENANT_ID" \
  "http://$SERVER_IP:9009/prometheus/api/v1/label/__name__/values" \
  -o /tmp/mimir_response3.json)

echo "HTTP Response: $response3"
if [[ "$response3" == "200" ]]; then
    echo "✅ Load Balancer 경로 연결 성공"
else
    echo "❌ Load Balancer 경로 연결 실패"
fi
echo ""

# 4. 테스트 메트릭 쿼리
echo "4️⃣ 테스트 메트릭 쿼리"
response4=$(curl -s -w "%{http_code}" -X GET \
  -H "X-Scope-OrgID: $TENANT_ID" \
  "http://$SERVER_IP:9009/api/v1/query?query=up" \
  -o /tmp/mimir_response4.json)

echo "HTTP Response: $response4"
if [[ "$response4" == "200" ]]; then
    echo "✅ 메트릭 쿼리 성공"
    cat /tmp/mimir_response4.json
else
    echo "❌ 메트릭 쿼리 실패"
fi
echo ""

# 정리
rm -f /tmp/mimir_response*.json

echo "📋 권장 해결책:"
echo "1. Response 200이 나오는 방법을 Grafana 데이터소스 URL로 사용"
echo "2. 멀티테넌시 연결이 실패하면 mimir.yaml에서 multitenancy_enabled: false 설정"
echo "3. Grafana에서 데이터소스 재생성" 