# Security Groups con mínimo privilegio: ningún 0.0.0.0/0 de entrada.
# El acceso administrativo es por SSM Session Manager, no por SSH.

resource "aws_security_group" "app" {
  count = var.enable_network ? 1 : 0

  name_prefix = "finops-app-"
  description = "APP: sin entrada publica; salida para instalacion y SSM"
  vpc_id      = aws_vpc.finops[0].id

  # Sin bloque ingress a propósito: nadie entra directo a la app.

  egress {
    description = "Salida a internet via NAT para paquetes, Docker y SSM"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "finops-app-sg" }
}

resource "aws_security_group" "data" {
  count = var.enable_network ? 1 : 0

  name_prefix = "finops-data-"
  description = "DATA: PostgreSQL solo desde el SG de APP"
  vpc_id      = aws_vpc.finops[0].id

  ingress {
    description     = "PostgreSQL unicamente desde las instancias de APP"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app[0].id]
  }

  egress {
    description = "Salida a internet via NAT para paquetes, Docker y SSM"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "finops-data-sg" }
}
