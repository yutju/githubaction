#!/bin/bash
# terraform ansible 전체 배포 스크립트

echo "[1/2] Terraform 인프라 생성을 시작합니다..."
cd ../terraform
terraform apply -auto-approve

echo "인벤토리 갱신 및 인스턴스 부팅 대기 중 (30s)..."
sleep 30

echo " [2/2] Ansible 프로비저닝을 시작합니다..."
cd ../ansible
ansible-playbook -i inventory/aws_ec2.yml site.yml 
# ansible-playbook -i inventory/aws_ec2.yml site.yml --ask-vault-pass  ansible vault 설정했을 경우 
