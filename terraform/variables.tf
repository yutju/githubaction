# variables.tf
# ============================================================
# [Comment] 인프라 공통 변수 설정
# ============================================================
variable "region" {
  description = "AWS 리전"
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr_1" {
  description = "퍼블릭 서브넷 1 CIDR (Bastion, NAT)"
  default     = "10.0.1.0/24"
}

variable "public_subnet_cidr_2" {
  description = "퍼블릭 서브넷 2 CIDR (ALB 이중화용)"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr_1" {
  description = "프라이빗 서브넷 1 CIDR (K3s)"
  default     = "10.0.11.0/24"
}

variable "private_subnet_cidr_2" {
  description = "프라이빗 서브넷 2 CIDR (Kafka, RDS)"
  default     = "10.0.12.0/24"
}

variable "availability_zone" {
  description = "가용 영역"
  default     = "ap-northeast-2a"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (서울 리전)"
  default     = "ami-08a4fd517a4872931"
}

variable "instance_type" {
  description = "EC2 인스턴스 타입"
  default     = "t3.small"
}

variable "key_name" {
  description = "AWS 키페어 이름"
  default     = "practice"
}

# ============================================================
# [추가] 고정 Private IP 변수 설정
# ============================================================

# [Comment]: 각 인스턴스에 고정으로 할당될 프라이빗 IP 주소들입니다.
# 서브넷 CIDR 대역(10.0.x.x)에 맞게 설정되어야 합니다!

variable "bastion_private_ip" {
  description = "Bastion Host 프라이빗 IP"
  default     = "10.0.1.10"
}

variable "nat_private_ip" {
  description = "NAT Instance 프라이빗 IP"
  default     = "10.0.1.20"
}

variable "k3s_master_private_ip" {
  description = "K3s Master 노드 프라이빗 IP"
  default     = "10.0.11.10"
}

variable "k3s_worker_private_ip" {
  description = "K3s Worker 노드 프라이빗 IP"
  default     = "10.0.11.20"
}

variable "k3s_worker_2_private_ip" {
  description = "K3s Worker 노드 2 프라이빗 IP"
  default     = "10.0.11.30"
}

variable "kafka_private_ip" {
  description = "Kafka 서버 프라이빗 IP"
  default     = "10.0.12.10"
}

variable "grafana_private_ip" {
  description = "Grafana 서버 프라이빗 IP"
  default     = "10.0.12.20"
}

