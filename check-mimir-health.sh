#!/bin/bash

# Mimir Health Check 스크립트
echo "🔍 Mimir 서비스 Health Check"
echo "========================================"

# Docker Compose 서비스 상태 확인
echo "📋 Docker Compose 서비스 상태:"
docker compose ps mimir-1 mimir-2 mimir-3 load-balancer

echo ""
echo "🏥 개별 Mimir 인스턴스 Health Check:"

# Mimir-1 health check
echo "1️⃣ Mimir-1 상태 확인"
response1=$(curl -s -w "%{http_code}" -X GET "http://localhost:8080/ready" -o /tmp/mimir1_health.json --connect-timeout 5 --max-time 10 2>/dev/null || echo "000")
if [[ "$response1" == "200" ]]; then
    echo "✅ Mimir-1: Healthy (HTTP $response1)"
else
    echo "❌ Mimir-1: Unhealthy (HTTP $response1)"
fi

# Mimir-2 health check (포트 포워딩 필요시)
echo "2️⃣ Mimir-2 상태 확인 (Docker 네트워크 내부)"
response2=$(docker exec master-mimir-2-1 wget -q --spider -T 5 http://localhost:8080/ready 2>/dev/null && echo "200" || echo "500")
if [[ "$response2" == "200" ]]; then
    echo "✅ Mimir-2: Healthy"
else
    echo "❌ Mimir-2: Unhealthy"
fi

# Mimir-3 health check
echo "3️⃣ Mimir-3 상태 확인 (Docker 네트워크 내부)"
response3=$(docker exec master-mimir-3-1 wget -q --spider -T 5 http://localhost:8080/ready 2>/dev/null && echo "200" || echo "500")
if [[ "$response3" == "200" ]]; then
    echo "✅ Mimir-3: Healthy"
else
    echo "❌ Mimir-3: Unhealthy"
fi

echo ""
echo "🌐 Load Balancer 테스트:"
response_lb=$(curl -s -w "%{http_code}" -X GET "http://localhost:9009/api/v1/status/buildinfo" -o /tmp/lb_health.json --connect-timeout 5 --max-time 10 2>/dev/null || echo "000")
if [[ "$response_lb" == "200" ]]; then
    echo "✅ Load Balancer: Healthy (HTTP $response_lb)"
else
    echo "❌ Load Balancer: Unhealthy (HTTP $response_lb)"
fi

echo ""
echo "📊 Mimir API 테스트:"
response_api=$(curl -s -w "%{http_code}" -X GET -H "X-Scope-OrgID: demo" "http://localhost:9009/api/v1/label/__name__/values" -o /tmp/api_test.json --connect-timeout 5 --max-time 10 2>/dev/null || echo "000")
if [[ "$response_api" == "200" ]]; then
    echo "✅ Mimir API: Working (HTTP $response_api)"
    echo "   Available metrics:"
    cat /tmp/api_test.json | head -3
else
    echo "❌ Mimir API: Failed (HTTP $response_api)"
fi

# 정리
rm -f /tmp/mimir*_health.json /tmp/lb_health.json /tmp/api_test.json

echo ""
echo "📋 권장 조치:"
echo "1. 모든 서비스가 Healthy면 정상 작동 중"
echo "2. Unhealthy 서비스가 있으면 해당 컨테이너 재시작"
echo "3. Load Balancer 실패시: docker compose restart load-balancer"
echo "4. API 실패시: X-Scope-OrgID 헤더 확인 필요" 