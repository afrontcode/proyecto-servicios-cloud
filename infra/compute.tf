# Cómputo del laboratorio: una EC2 de aplicación y una de datos, ambas en
# subredes privadas y sin IP pública. El acceso es por SSM Session Manager.

data "aws_ssm_parameter" "al2023" {
  count = var.enable_compute && var.ami_id == "" ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

locals {
  selected_ami = var.ami_id != "" ? var.ami_id : (var.enable_compute ? data.aws_ssm_parameter.al2023[0].value : "")
}

# --- Rol IAM que permite el acceso por SSM sin abrir SSH ---

resource "aws_iam_role" "ec2_ssm" {
  count = var.enable_compute ? 1 : 0

  name_prefix = "finops-ssm-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count = var.enable_compute ? 1 : 0

  role       = aws_iam_role.ec2_ssm[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.enable_compute ? 1 : 0

  name_prefix = "finops-ec2-"
  role        = aws_iam_role.ec2_ssm[0].name
}

# --- Instancias ---

resource "aws_instance" "app" {
  count = var.enable_compute ? 1 : 0

  ami                         = local.selected_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.app[0].id
  vpc_security_group_ids      = [aws_security_group.app[0].id]
  iam_instance_profile        = aws_iam_instance_profile.ec2[0].name
  associate_public_ip_address = false

  # Instala Docker y el plugin compose al primer arranque
  user_data                   = file("${path.module}/user_data_app.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    precondition {
      condition     = var.enable_network && var.enable_nat
      error_message = "Las EC2 privadas necesitan enable_network y enable_nat para SSM, paquetes del SO y descarga de imagenes Docker."
    }
  }

  tags = {
    Name = "finops-app"
    Role = "app"
  }
}

resource "aws_instance" "data" {
  count = var.enable_compute ? 1 : 0

  ami                         = local.selected_ami
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.data[0].id
  vpc_security_group_ids      = [aws_security_group.data[0].id]
  iam_instance_profile        = aws_iam_instance_profile.ec2[0].name
  associate_public_ip_address = false

  # Instala Docker y prepara el volumen EBS persistente de PostgreSQL
  user_data                   = file("${path.module}/user_data_data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = var.root_volume_gb
    volume_type = "gp3"
    encrypted   = true
  }

  lifecycle {
    precondition {
      condition     = var.enable_network && var.enable_nat
      error_message = "Las EC2 privadas necesitan enable_network y enable_nat en este diseno de laboratorio."
    }
  }

  tags = {
    Name = "finops-data"
    Role = "data"
  }
}

# --- Disco de datos de PostgreSQL (persistencia tras reinicio) ---

resource "aws_ebs_volume" "postgres" {
  count = var.enable_compute ? 1 : 0

  availability_zone = aws_subnet.data[0].availability_zone
  size              = var.data_volume_gb
  type              = "gp3"
  encrypted         = true

  tags = { Name = "finops-postgres-data" }
}

resource "aws_volume_attachment" "postgres" {
  count = var.enable_compute ? 1 : 0

  device_name                    = "/dev/sdf"
  volume_id                      = aws_ebs_volume.postgres[0].id
  instance_id                    = aws_instance.data[0].id
  stop_instance_before_detaching = true
}
