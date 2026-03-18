# ============================================================
# Bastion Host SG (수정 없음)
# ============================================================
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "bastion-sg" }
}

# ============================================================
# NAT Instance SG 
# ============================================================
resource "aws_security_group" "nat_sg" {
  name        = "nat-instance-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Traffic from ALL private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nat-instance-sg" }
}

# ============================================================
# Private Service SG (K3s, Kafka, Grafana용 공용)
# ============================================================
resource "aws_security_group" "private_sg" {
  name        = "private-service-sg"
  vpc_id      = aws_vpc.main.id

  # 1. SSH 관리 (Bastion에서만 가능)
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # 2. K3s 내부 통신 (Master-Worker 간 API 통신 등)
  ingress {
    description = "K3s API Server & Internal"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    self        = true # 이 SG를 가진 서버끼리 통신 허용
  }

  # 3. Kafka 통신 (기본 9092)
  ingress {
    description = "Kafka Broker"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # 4. Grafana 접속 (기본 3000)
  ingress {
    description = "Grafana Web UI"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Allow all internal traffic within VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" 
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "private-service-sg" }
}

# ============================================================
# RDS 전용 보안 그룹
# ============================================================
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "MySQL from private services"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    # Private SG를 가진 서버들만 DB 접속 가능
    security_groups = [aws_security_group.private_sg.id]
  }

  tags = { Name = "rds-sg" }
}

# ============================================================
# ALB SG
# ============================================================
resource "aws_security_group" "alb_sg" {
  name        = "sixsense-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "sixsense-alb-sg" }
}
