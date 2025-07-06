#!/bin/bash

# --- Libvirt 설치 스크립트 (OpenStack 컴퓨트 노드 역할을 할 VM 내부에서 실행) ---
# 이 스크립트는 Proxmox 위에 올라간 Ubuntu/Debian 기반의 VM (OpenStack 컴퓨트 노드)에서 실행되어야 합니다.
# 이 VM은 Prometheus Libvirt Exporter가 연결할 대상입니다.

echo "Libvirt 및 KVM 관련 패키지 설치를 시작합니다..."

# 시스템 패키지 목록 업데이트
sudo apt update -y

# Libvirt 및 KVM 관련 핵심 패키지 설치
# libvirt-daemon-system: Libvirt 데몬 및 시스템 서비스
# libvirt-clients: Libvirt 명령줄 도구 (virsh 등)
# qemu-kvm: KVM 가상화를 위한 QEMU 바이너리
# bridge-utils: 네트워크 브리징 도구 (가상 네트워크 설정에 필요)
# virtinst: 가상 머신 생성 도구 (옵션, OpenStack Nova가 대신 처리할 것임)
sudo apt install -y libvirt-daemon-system libvirt-clients qemu-kvm bridge-utils virtinst

if [ $? -ne 0 ]; then
    echo "오류: Libvirt 패키지 설치 중 문제가 발생했습니다. 네트워크 연결 또는 저장소를 확인하세요."
    exit 1
fi

echo "Libvirt 패키지 설치 완료."

echo "Libvirt 서비스 활성화 및 시작 확인..."
# Libvirt 데몬 서비스 활성화 및 시작
sudo systemctl enable libvirtd
sudo systemctl start libvirtd

# 서비스 상태 확인
if sudo systemctl is-active --quiet libvirtd; then
    echo "Libvirt 데몬 (libvirtd) 서비스가 성공적으로 실행 중입니다."
else
    echo "오류: Libvirt 데몬 (libvirtd) 서비스 시작에 실패했습니다. 로그를 확인하세요 (journalctl -xeu libvirtd)."
    exit 1
fi

echo "Libvirt 그룹에 현재 사용자 추가 (선택 사항, 그러나 docker 사용자 권한 문제 해결에 중요)"
# 현재 사용자를 'libvirt' 그룹에 추가하여 sudo 없이 Libvirt에 접근할 수 있도록 합니다.
# 만약 docker 컨테이너가 호스트의 /var/run/libvirt/libvirt-sock 에 접근하려면,
# 도커 데몬을 실행하는 사용자(일반적으로 root 또는 docker 그룹의 사용자)가 libvirt 그룹에 속해야 합니다.
# 테스트베드에서는 docker를 root로 실행할 가능성이 높으므로, 이 VM에 docker를 설치하고 그 사용자를 추가할 수도 있습니다.
# 여기서는 일반적인 시나리오를 위해 현재 로그인한 사용자를 추가합니다.
CURRENT_USER=$(whoami)
sudo usermod -aG libvirt "$CURRENT_USER"
sudo usermod -aG kvm "$CURRENT_USER" # KVM 그룹에도 추가

echo "사용자 '$CURRENT_USER'를 'libvirt' 및 'kvm' 그룹에 추가했습니다."
echo "변경 사항을 적용하려면 재로그인하거나 VM을 재부팅해야 할 수 있습니다."

echo "KVM 가상화 지원 확인..."
# KVM 모듈이 로드되어 있는지 확인
if lsmod | grep -q kvm; then
    echo "KVM 모듈이 로드되어 있습니다."
else
    echo "KVM 모듈이 로드되지 않았습니다. VT-x/AMD-V 가상화 기능이 VM 설정에서 활성화되었는지 확인하세요."
    echo "대부분 Proxmox VM은 자동으로 가상화 기능을 패스스루합니다."
fi

# Libvirt 기본 네트워크 브리지 (virbr0) 상태 확인 (선택 사항)
echo "Libvirt 기본 네트워크 브리지 (virbr0) 상태 확인..."
if virsh net-list --all | grep -q default; then
    echo "Libvirt 'default' 네트워크가 존재합니다."
    if virsh net-info default | grep -q "Active: yes"; then
        echo "Libvirt 'default' 네트워크가 활성 상태입니다."
    else
        echo "Libvirt 'default' 네트워크가 비활성 상태입니다. 활성화합니다."
        sudo virsh net-start default
        sudo virsh net-autostart default
    fi
else
    echo "Libvirt 'default' 네트워크가 존재하지 않습니다. OpenStack이 네트워크를 구성하므로 이 단계는 중요하지 않을 수 있습니다."
fi

echo "Libvirt 설치 및 기본 설정 완료."
echo "이제 이 VM은 Libvirt Exporter가 연결할 수 있는 Libvirt 환경을 갖추었습니다."
echo "Libvirt Exporter 컨테이너가 이 VM의 /var/run/libvirt/libvirt-sock에 접근할 수 있도록 볼륨 마운트가 올바른지 확인하십시오."
echo "필요하다면 VM을 재부팅하여 그룹 변경 사항을 적용하십시오."