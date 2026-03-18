#!/bin/bash 
# 인스턴스 껐다 켰을때 Bastion 퍼블릭ip 바뀔때 terraform output 새로고침

# 1. 경로 설정: 스크립트와 Terraform 파일 위치를 찾습니다.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/../terraform"

# 2. 정보 갱신: AWS 서버에 물어봐서 바뀐 IP 정보를 내 컴퓨터 기록에 업데이트합니다.
terraform -chdir="$TERRAFORM_DIR" refresh > /dev/null

# 3. IP 추출: 업데이트된 기록에서 Bastion 서버의 새 접속 주소(Public IP)만 가져옵니다.
BASTION_IP=$(terraform -chdir="$TERRAFORM_DIR" output -raw bastion_public_ip)

# 4. 결과 출력: 바뀐 IP를 화면에 보여줍니다.
echo "--------------------------------------------------"
echo "New Bastion Public IP: $BASTION_IP"
echo "--------------------------------------------------"
echo "Done. Now you can use bastion-connect.sh or check-status.sh"
