#!/bin/bash

# 마스터 노드 (중앙 모니터링) 실행 스크립트
echo "🏗️ Mimir 마스터 노드 시작..."

# 현재 디렉토리 확인
if [ ! -f "docker-compose.yml" ]; then
    echo "❌ docker-compose.yml 파일을 찾을 수 없습니다."
    echo "   master/ 디렉토리에서 실행하세요."
    exit 1
fi

# 필요한 디렉토리 확인
if [ ! -d "config" ] || [ ! -d "mimir-mixin-compiled" ]; then
    echo "❌ 필수 디렉토리가 없습니다. config/ 및 mimir-mixin-compiled/ 디렉토리가 필요합니다."
    exit 1
fi

# Docker 및 Docker Compose 확인
if ! command -v docker &> /dev/null; then
    echo "❌ Docker가 설치되어 있지 않습니다."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose가 설치되어 있지 않습니다."
    exit 1
fi

# 기존 컨테이너 정리 여부 확인
read -p "🧹 기존 컨테이너를 정리하시겠습니까? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🧹 기존 컨테이너 정리..."
    docker-compose down -v
    echo "✅ 정리 완료"
fi

# 마스터 노드 시작
echo "🚀 마스터 노드 시작 중..."
docker-compose up -d

# 서비스 시작 대기
echo "⏳ 서비스 시작 대기 중 (30초)..."
sleep 30

# 상태 확인
echo "📋 컨테이너 상태 확인:"
docker-compose ps

# 헬스체크
echo ""
echo "🔍 서비스 헬스체크:"

# Mimir 클러스터 확인
if curl -s http://localhost:9009/ready > /dev/null; then
    echo "   ✅ Mimir 클러스터: 정상"
else
    echo "   ⚠️ Mimir 클러스터: 확인 필요"
fi

# Grafana 확인
if curl -s http://localhost:9000/api/health > /dev/null; then
    echo "   ✅ Grafana: 정상"
else
    echo "   ⚠️ Grafana: 확인 필요"
fi

# MinIO 확인
if curl -s http://localhost:19000 > /dev/null; then
    echo "   ✅ MinIO: 정상"
else
    echo "   ⚠️ MinIO: 확인 필요"
fi

echo ""
echo "🌐 접근 주소:"
echo "   📊 Grafana: http://localhost:9000"
echo "   🗄️ Mimir API: http://localhost:9009"
echo "   🔔 Alertmanager: http://localhost:9093"
echo "   💾 MinIO Console: http://localhost:19000 (mimir/supersecret)"

echo ""
echo "📝 유용한 명령어:"
echo "   📋 상태 확인: docker-compose ps"
echo "   📊 로그 확인: docker-compose logs -f [서비스명]"
echo "   🛑 중지: docker-compose down"
echo "   🔄 재시작: docker-compose restart [서비스명]"

echo ""
echo "✅ 마스터 노드가 성공적으로 시작되었습니다!"

# 로컬 IP 확인
LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}')
if [ ! -z "$LOCAL_IP" ]; then
    echo "   워커 노드 연결 URL: http://$LOCAL_IP:9009"
else
    echo "   워커 노드 연결 URL: http://[이_서버의_IP]:9009"
fi
