#!/bin/bash

# 1. 경로 설정
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
KEY_PATH="$SCRIPT_DIR/../sixsense-test.pem"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo "Terraform에서 인프라 정보를 추출하는 중..."

# 2. Terraform Output에서 정확한 변수명으로 IP 추출
BASTION_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw bastion_public_ip 2>/dev/null) 
MASTER_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw k3s_master_private_ip 2>/dev/null)
KAFKA_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw kafka_private_ip 2>/dev/null)     
GRAFANA_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw grafana_private_ip 2>/dev/null)

# 3. 유효성 체크
if [ -z "$BASTION_IP" ] || [ "$BASTION_IP" = "null" ]; then
    echo "에러: Bastion IP를 가져오지 못했습니다."
    exit 1
fi

echo "정보 획득 완료!"
echo "Bastion: $BASTION_IP"
echo "Master : $MASTER_IP"
echo "Kafka  : $KAFKA_IP"
echo "Grafana: $GRAFANA_IP"
echo "--------------------------------------------------"

# SSH Agent 실행 및 키 등록
# Bastion 서버를 거쳐 내부 서버로 인증 정보를 전달하기 위함입니다.
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
fi
ssh-add "$KEY_PATH" 2>/dev/null

# 4. K3s 노드 상태 확인 (Master 접속)
echo "[K3s Cluster Status]"
ssh -A -i "$KEY_PATH" \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -J ubuntu@"$BASTION_IP" \
    ubuntu@"$MASTER_IP" "kubectl get nodes"

# 5. 주요 서비스 포트 상태 확인 (Kafka, Grafana 서버 직접 체크)
echo ""
echo "[Service Connectivity Check]"
echo -n "Kafka (9092): "
ssh -A -i "$KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J ubuntu@"$BASTION_IP" ubuntu@"$KAFKA_IP" "nc -zv localhost 9092 2>&1" | grep -o "succeeded!" || echo "Failed"

echo -n "Grafana (3000): "
ssh -A -i "$KEY_PATH" -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -J ubuntu@"$BASTION_IP" ubuntu@"$GRAFANA_IP" "nc -zv localhost 3000 2>&1" | grep -o "succeeded!" || echo "Failed"
