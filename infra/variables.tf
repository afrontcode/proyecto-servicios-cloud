variable "aws_region" {
  description = "Región de AWS. La SCP de la organización solo permite us-east-2."
  type        = string
  default     = "us-east-2"
}

variable "enable_network" {
  description = "Crea VPC, subredes, IGW y tablas de rutas. Sin costo por sí mismo."
  type        = bool
  default     = false
}

variable "enable_nat" {
  description = "Crea NAT Gateway y su Elastic IP. CUESTA ~0.045 USD/hora aunque las EC2 estén detenidas."
  type        = bool
  default     = false
}

variable "enable_compute" {
  description = "Crea las EC2, el rol IAM y el EBS de datos. Requiere enable_network y enable_nat."
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Tipo de instancia de las EC2 del laboratorio."
  type        = string
  default     = "t3.micro"

  validation {
    # Guardarraíl de costo del proyecto: nada por encima de t3.small
    condition     = contains(["t3.nano", "t3.micro", "t3.small"], var.instance_type)
    error_message = "Solo se permiten t3.nano, t3.micro y t3.small."
  }
}

variable "ami_id" {
  description = "AMI fija opcional. Vacío = Amazon Linux 2023 resuelta por SSM."
  type        = string
  default     = ""
}

variable "root_volume_gb" {
  description = "Tamaño del disco raíz de cada EC2, en GB."
  type        = number
  default     = 12
}

variable "data_volume_gb" {
  description = "Tamaño del EBS adicional para los datos de PostgreSQL, en GB."
  type        = number
  default     = 8
}

variable "budget_limit_usd" {
  description = "Solo informativo: no crea ninguna alarma de presupuesto."
  type        = number
  default     = 10
}
