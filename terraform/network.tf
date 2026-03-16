# ============================================================
# VPC 및 인터넷 게이트웨이 (기존 에러 해결을 위해 추가됨)
# ============================================================

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "SixSense-VPC" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "SixSense-IGW" }
}

# ============================================================
# 서브넷 (Subnets)
# ============================================================

# Public Subnet (Bastion, NAT Instance 위치)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "ap-northeast-2a" # 가용 영역 A
  tags = { Name = "public-subnet" }
}

# Private Subnet 1 (K3s Cluster 위치)
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24" # 적절한 CIDR 할당
  availability_zone = "ap-northeast-2a" # 가용 영역 A
  tags = { Name = "private-subnet-1" }
}

# Private Subnet 2 (Kafka, Monitoring, RDS 위치)
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24" # 적절한 CIDR 할당
  availability_zone = "ap-northeast-2c" # 가용 영역 C (RDS 다중 AZ 고려)
  tags = { Name = "private-subnet-2" }
}

# ============================================================
# 라우팅 테이블 (Routing Tables)
# ============================================================

# Public RT: IGW 연결
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Private RT: 모든 프라이빗 트래픽을 NAT Instance로 전달
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_instance.primary_network_interface_id
  }
  tags = { Name = "private-rt" }
}

# 프라이빗 서브넷 1 연결
resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# 프라이빗 서브넷 2 연결
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}
