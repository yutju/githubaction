#!/bin/bash

# 스크립트 위치
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

KEY_PATH="$SCRIPT_DIR/../sixsense-test.pem"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

echo ">>> Bastion IP 정보를 가져오는 중..."

# Bastion IP 가져오기
BASTION_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw bastion_public_ip 2>/dev/null)

if [ -z "$BASTION_IP" ]; then
    echo "에러: Terraform에서 Bastion IP를 가져오지 못했습니다."
    echo "확인: terraform apply가 실행되었는지, output이 정의되어 있는지 확인하세요."
    exit 1
fi

echo ">>> Bastion IP: $BASTION_IP"

# Private IP 입력
if [ -z "$1" ]; then
    read -p ">>> 접속할 Private IP를 입력하세요: " PRIVATE_IP
else
    PRIVATE_IP=$1
fi

if [ -z "$PRIVATE_IP" ]; then
    echo "에러: Private IP가 입력되지 않았습니다."
    exit 1
fi

echo ">>> Target Private IP: $PRIVATE_IP"

# PEM 키 확인
if [ ! -f "$KEY_PATH" ]; then
    echo "에러: PEM 키 파일을 찾을 수 없습니다."
    echo "경로: $KEY_PATH"
    exit 1
fi

# SSH Agent 실행
if [ -z "$SSH_AUTH_SOCK" ]; then
    echo ">>> SSH Agent 시작"
    eval "$(ssh-agent -s)" >/dev/null
fi

ssh-add "$KEY_PATH" >/dev/null 2>&1

echo ">>> Bastion($BASTION_IP)을 통해 $PRIVATE_IP 접속 중..."

ssh -A \
-i "$KEY_PATH" \
-o StrictHostKeyChecking=no \
-o UserKnownHostsFile=/dev/null \
-J ubuntu@"$BASTION_IP" \
ubuntu@"$PRIVATE_IP"
