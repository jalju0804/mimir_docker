#!/bin/bash

echo "🔍 Mimir 연결 테스트 시작..."

# 컬러 출력 설정
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 테스트 함수
test_endpoint() {
    local url=$1
    local tenant=$2
    local description=$3
    
    echo -e "\n${YELLOW}🧪 테스트: ${description}${NC}"
    echo "   URL: $url"
    echo "   Tenant: $tenant"
    
    if [ -n "$tenant" ]; then
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" -H "X-Scope-OrgID: $tenant" "$url")
    else
        response=$(curl -s -w "HTTPSTATUS:%{http_code}" "$url")
    fi
    
    http_code=$(echo $response | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    body=$(echo $response | sed -e 's/HTTPSTATUS\:.*//g')
    
    if [ "$http_code" == "200" ]; then
        echo -e "   ${GREEN}✅ 성공 (HTTP $http_code)${NC}"
        echo "   응답: $(echo $body | head -c 100)..."
    else
        echo -e "   ${RED}❌ 실패 (HTTP $http_code)${NC}"
        echo "   응답: $body"
    fi
}

# Load Balancer 엔드포인트 확인
echo -e "\n${YELLOW}🔍 Load Balancer 테스트${NC}"
test_endpoint "http://localhost:9009/health" "" "Load Balancer Health Check"

# Mimir 엔드포인트 테스트 (X-Scope-OrgID 없이)
echo -e "\n${YELLOW}🔍 Mimir 기본 엔드포인트 (헤더 없이)${NC}"
test_endpoint "http://localhost:9009/api/v1/query?query=up" "" "기본 쿼리 (헤더 없음)"

# Mimir 엔드포인트 테스트 (demo 테넌트)
echo -e "\n${YELLOW}🔍 Mimir 엔드포인트 (demo 테넌트)${NC}"
test_endpoint "http://localhost:9009/api/v1/query?query=up" "demo" "Demo 테넌트 쿼리"

# Mimir 엔드포인트 테스트 (prod 테넌트)
echo -e "\n${YELLOW}🔍 Mimir 엔드포인트 (prod 테넌트)${NC}"
test_endpoint "http://localhost:9009/api/v1/query?query=up" "prod" "Production 테넌트 쿼리"

# Prometheus API 경로 테스트
echo -e "\n${YELLOW}🔍 Prometheus API 경로 테스트${NC}"
test_endpoint "http://localhost:9009/prometheus/api/v1/query?query=up" "demo" "Prometheus API 경로 (demo)"

# Grafana에서 사용하는 경로 테스트
echo -e "\n${YELLOW}🔍 Grafana 통합 테스트${NC}"
test_endpoint "http://localhost:9009/prometheus/api/v1/label/__name__/values" "demo" "라벨 값 조회 (Grafana 사용)"

# 메트릭 라벨 확인
echo -e "\n${YELLOW}🔍 사용 가능한 메트릭 확인${NC}"
test_endpoint "http://localhost:9009/prometheus/api/v1/label/__name__/values" "demo" "메트릭 목록 조회"

# 실제 메트릭 쿼리
echo -e "\n${YELLOW}🔍 실제 메트릭 쿼리 테스트${NC}"
test_endpoint "http://localhost:9009/prometheus/api/v1/query?query=prometheus_build_info" "demo" "Prometheus Build Info"

# 현재 시간의 시계열 데이터 조회
echo -e "\n${YELLOW}🔍 시계열 데이터 조회 테스트${NC}"
now=$(date +%s)
start=$((now - 3600))  # 1시간 전
test_endpoint "http://localhost:9009/prometheus/api/v1/query_range?query=up&start=${start}&end=${now}&step=60" "demo" "시계열 데이터 (1시간)"

echo -e "\n${GREEN}🎯 테스트 완료!${NC}"
echo -e "\n💡 해석:"
echo "  - HTTP 200: 정상 작동"
echo "  - HTTP 401: X-Scope-OrgID 헤더 누락 또는 인증 문제"
echo "  - HTTP 404: 엔드포인트 경로 문제"
echo "  - HTTP 500: Mimir 내부 오류"

echo -e "\n🛠️  문제 해결:"
echo "  1. HTTP 401 오류가 나오면 Grafana 데이터소스의 헤더 설정 확인"
echo "  2. HTTP 404 오류가 나오면 URL 경로 확인"
echo "  3. 모든 테스트가 실패하면 Docker 서비스 상태 확인" 