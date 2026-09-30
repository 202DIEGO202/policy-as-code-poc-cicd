# ============================================================
# VPC
# Red privada principal
# ============================================================

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "Demo-vpc"
    Environment = "DEV"
  }
}


# ============================================================
# SUBNET
# Segmento de red donde estará el servidor
# ============================================================

resource "aws_subnet" "web" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name        = "Demo-web-subnet"
    Environment = "DEV"
  }
}