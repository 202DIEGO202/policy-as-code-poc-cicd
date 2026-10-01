# ============================================================
# INSTANCIA EC2
# Servidor virtual
# ============================================================

resource "aws_instance" "web" {

  ami           = var.ami_id
  instance_type = "t3.micro"

  subnet_id = aws_subnet.web.id

  vpc_security_group_ids = [
    aws_security_group.web.id
  ]


  # ----------------------------------------------------------
  # Disco principal EBS
  # INTENCIONALMENTE SIN CIFRADO
  # ----------------------------------------------------------

  root_block_device {
    encrypted = false
  }


  # ----------------------------------------------------------
  # Etiquetas
  # ----------------------------------------------------------

  tags = {
    Name        = "web-server"
    Environment = "DEV"
    Owner       = "Equipo-Arquitectura"
  }
}