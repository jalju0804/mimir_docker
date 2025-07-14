#!/bin/bash

# 워커 노드 실행 스크립트
echo "🚀 워커 노드 모니터링 시작..."

# 환경 변수 파일 확인
if [ ! -f "worker-node.env" ]; then
    echo "⚠️  worker-node.env 파일이 없습니다. 예시 파일을 복사하여 설정하세요."
    if [ -f "worker-node.env.example" ]; then
        cp worker-node.env.example worker-node.env
        echo "📝 worker-node.env 파일이 생성되었습니다. 설정을 수정하세요."
        echo "   - WORKER_NODE_NAME: 현재 노드 이름"
        echo "   - CENTRAL_MIMIR_URL: 중앙 Mimir 엔드포인트"
        exit 1
    else
        echo "❌ worker-node.env.example 파일도 없습니다."
        exit 1
    fi
fi

# 필요한 디렉토리 생성
mkdir -p config logs

# 권한 확인 (ICMP 프로브를 위해 필요)
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  ICMP 프로브를 위해 sudo 권한이 필요할 수 있습니다."
    echo "   sudo docker compose up -d"
    exit 1
fi

# 기존 컨테이너 정리
echo "🧹 기존 컨테이너 정리..."
docker compose down

# 환경 변수 로드
set -a
source worker-node.env
set +a

echo "📊 워커 노드 정보:"
echo "   - 노드 이름: $WORKER_NODE_NAME"
echo "   - 중앙 Mimir URL: $CENTRAL_MIMIR_URL"

# 컨테이너 시작
echo "🔄 컨테이너 시작 중..."
docker compose up -d

# 헬스체크 대기
echo "⏳ 서비스 시작 대기 중..."
sleep 10

# 상태 확인
echo "📋 컨테이너 상태 확인:"
docker compose ps

# 연결 테스트
echo "🔍 연결 테스트:"
echo "   - Node Exporter: http://localhost:9100/metrics"
echo "   - cAdvisor: http://localhost:8080/metrics"
echo "   - Blackbox Exporter: http://localhost:9115/metrics"
echo "   - Process Exporter: http://localhost:9256/metrics"
echo "   - MySQL Exporter: http://localhost:9104/metrics"
echo "   - RabbitMQ Exporter: http://localhost:9419/metrics"
echo "   - Libvirt Exporter: http://localhost:9177/metrics"
echo "   - Prometheus Agent: http://localhost:9090"
echo "   - MySQL DB: localhost:3306"
echo "   - RabbitMQ Management: http://localhost:15672 (admin/admin123)"

# 로그 확인 옵션
echo ""
echo "📝 로그 확인:"
echo "   docker compose logs -f prometheus-agent"
echo ""
echo "🛑 중지:"
echo "   docker compose down"

echo "✅ 워커 노드 모니터링이 시작되었습니다!" 