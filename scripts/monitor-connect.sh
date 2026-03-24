#!/bin/bash

# --- 1. 스크립트 위치 및 경로 설정 ---
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 키 파일 이름을 변수로 처리 (환경 변수가 없으면 기본값 practice.pem)
KEY_NAME="${KEY_NAME:-practice.pem}"
KEY_PATH="$SCRIPT_DIR/../$KEY_NAME"

BASTION_NAME_TAG="Bastion-Host"
REGION="ap-northeast-2"

# 사설 IP 설정
GRAFANA_IP="10.0.12.20"
PROMETHEUS_IP="10.0.12.20"

echo ">>> 사용 중인 키 파일: $KEY_NAME"
echo "[${REGION}]에서 Bastion(Name=${BASTION_NAME_TAG}) IP 조회 중..."

# --- 2. Bastion IP 조회 ---
BASTION_IP=$(aws ec2 describe-instances \
    --region ${REGION} \
    --filters "Name=tag:Name,Values=${BASTION_NAME_TAG}" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[0].PublicIpAddress" \
    --output text)

if [ "$BASTION_IP" = "None" ] || [ -z "$BASTION_IP" ]; then
    echo "에러: 실행 중인 Bastion IP를 찾지 못했습니다."
    exit 1
fi

# --- 3. 키 파일 존재 확인 ---
if [ ! -f "$KEY_PATH" ]; then
    echo "에러: 키 파일을 찾을 수 없습니다: $KEY_PATH"
    echo "팁: KEY_NAME=파일명.pem ./monitor-connect.sh 형식으로 실행하세요."
    exit 1
fi

# SSH 권한 최적화
chmod 400 "$KEY_PATH"

echo "Bastion IP 발견: ${BASTION_IP}"
echo "-------------------------------------------------------"
echo "모니터링 터널링 시작"
echo "Grafana:     http://localhost:8000"
echo "Prometheus:  http://localhost:9000"
echo "-------------------------------------------------------"
echo "종료하려면 Ctrl+C를 누르세요."

# --- 4. SSH 터널링 (멀티 포트 포워딩) ---
# -N: 원격 명령 실행 없이 터널링만 유지
ssh -i "${KEY_PATH}" -N \
    -L 8000:${GRAFANA_IP}:3000 \
    -L 9000:${PROMETHEUS_IP}:9090 \
    -o StrictHostKeyChecking=no \
    ubuntu@${BASTION_IP}
