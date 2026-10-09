# ============================================================
# SECURITY GROUP
# Reglas de acceso al servidor
# ============================================================

resource "aws_security_group" "web" {
  name        = "Demo-web-sg"
  description = "Reglas de acceso para servidor web"
  vpc_id      = aws_vpc.main.id


  # ----------------------------------------------------------
  # HTTPS
  # Permitido desde Internet
  # ----------------------------------------------------------

  ingress {
    description = "HTTPS"

    from_port = 443
    to_port   = 443
    protocol  = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }


  # ----------------------------------------------------------
  # SSH
  # INTENCIONALMENTE INSEGURO PARA LA DEMOSTRACION
  # ----------------------------------------------------------

  ingress {
    description = "SSH"

    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = ["10.0.0.0/24"]
  }
}