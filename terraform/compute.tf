# ============================================================
# 앤서블용 IAM Role 설정 추가
# ============================================================
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ansible_role" {
  name               = "sixsense-ansible-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.ansible_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ansible_profile" {
  name = "sixsense-ansible-profile"
  role = aws_iam_role.ansible_role.name
}

# ============================================================
# Bastion Host (Public 서브넷)
# ============================================================
resource "aws_instance" "bastion" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_subnet_a.id
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ansible_profile.name
  private_ip = var.bastion_private_ip

  tags = {
    Name    = "Bastion-Host"
    Role    = "bastion"     # Ansible 그룹: @bastion
    Project = "SixSense"
  }
}

# ============================================================
# NAT Instance (Public 서브넷)
# ============================================================
resource "aws_instance" "nat_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.nat_sg.id]
  key_name               = var.key_name
  source_dest_check = false
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name 
  private_ip = var.nat_private_ip

  user_data = <<-EOF
    #!/bin/bash
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    sysctl -p
    iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
    netfilter-persistent save
  EOF

  tags = {
    Name    = "NAT-Instance"
    Role    = "nat"         # Ansible 그룹: @nat
    Project = "SixSense"
  }
}

# ============================================================
# [Private Subnet 1] K3s Cluster
# ============================================================

# K3s Master 노드
resource "aws_instance" "k3s_master" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name
  private_ip = var.k3s_master_private_ip

  depends_on = [aws_instance.nat_instance]

  tags = {
    Name    = "K3s-Master"
    Role    = "master"      # Ansible 그룹: @master
    Project = "SixSense"
  }
}

# K3s Worker 노드
resource "aws_instance" "k3s_worker" {
  ami                    = var.ami_id
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name
  private_ip = var.k3s_worker_private_ip

  depends_on = [aws_instance.k3s_master]

  tags = {
    Name    = "K3s-Worker-1"
    Role    = "worker"      # Ansible 그룹: @worker
    Project = "SixSense"
  }
}

# ============================================================
# [Private Subnet 2] Infra Services (Kafka, Grafana)
# ============================================================

# Kafka 전용 서버
resource "aws_instance" "kafka_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name
  private_ip = var.kafka_private_ip

  depends_on = [aws_instance.nat_instance]

  tags = {
    Name    = "Kafka-Server"
    Role    = "kafka"       
    Project = "SixSense"
  }
}

# Grafana 모니터링 서버
resource "aws_instance" "grafana_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_name
  iam_instance_profile   = aws_iam_instance_profile.ansible_profile.name
  private_ip = var.grafana_private_ip

  depends_on = [aws_instance.nat_instance]

  tags = {
    Name    = "Grafana-Server"
    Role    = "monitoring"  
    Project = "SixSense"
  }
}

# ============================================================
# Amazon RDS (MySQL)
# ============================================================

resource "aws_db_subnet_group" "rds_sg_group" {
  name       = "sixsense-rds-group"
  subnet_ids = [aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]     
  tags       = { 
    Name    = "SixSense-RDS-Subnet-Group"
    Project = "SixSense"
  }
}

resource "aws_db_instance" "rds_instance" {
  identifier             = "sixsense-rds"

  allocated_storage      = 20
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  db_name                = "sixsensedb"
  username               = "admin"
  password               = "password123" 
  db_subnet_group_name   = aws_db_subnet_group.rds_sg_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true

  tags = { 
    Name    = "SixSense-RDS"
    Role    = "rds"         # RDS 식별용 태그
    Project = "SixSense"
  }
}
