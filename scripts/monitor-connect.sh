#!/bin/bash

# --- 설정 변수 ---
KEY_PATH="${HOME}/sixsense-test/sixsense-test.pem"
BASTION_NAME_TAG="Bastion-Host"
REGION="ap-northeast-2"

# 사설 IP 설정 (준수님 환경에 맞게 확인)
GRAFANA_IP="10.0.12.20"    # grafana가 설치된 인스턴스의 프라이빗 ip  테라폼 코드에서 프라이빗 ip 고정했기 때문에 이걸 사용해야됨 
PROMETHEUS_IP="10.0.12.20" # 위와 동일

echo "[${REGION}]에서 Bastion(Name=${BASTION_NAME_TAG}) IP 조회 중..."

BASTION_IP=$(aws ec2 describe-instances \
    --region ${REGION} \
    --filters "Name=tag:Name,Values=${BASTION_NAME_TAG}" "Name=instance-state-name,Values=running" \
    --query "Reservations[].Instances[0].PublicIpAddress" \
    --output text)

if [ "$BASTION_IP" = "None" ] || [ -z "$BASTION_IP" ]; then
    echo "에러: 실행 중인 Bastion IP를 찾지 못했습니다."
    exit 1
fi

if [ ! -f "$KEY_PATH" ]; then
    echo " 에러: 키 파일을 찾을 수 없습니다: $KEY_PATH"
    exit 1
fi

echo "Bastion IP 발견: ${BASTION_IP}"
echo "-------------------------------------------------------"
echo "모니터링 터널링 시작"
echo "Grafana:     http://localhost:8000"
echo "Prometheus:  http://localhost:9000"
echo "-------------------------------------------------------"
echo "종료하려면 Ctrl+C를 누르세요."

# SSH 터널링 (멀티 포트 포워딩)
# -L 8000 -> 그라파나(3000)
# -L 9000 -> 프로메테우스(9090)
ssh -i "${KEY_PATH}" -N \
    -L 8000:${GRAFANA_IP}:3000 \
    -L 9000:${PROMETHEUS_IP}:9090 \
    ubuntu@${BASTION_IP} -o StrictHostKeyChecking=no
