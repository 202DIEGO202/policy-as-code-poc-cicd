terraform {
  required_version = ">= 1.0.0"
}

# ============================================================
# PoC - Policy as Code
#
# Esta configuración representa un servidor que un equipo
# desea llevar posteriormente a despliegue.
#
# IMPORTANTE:
# Terraform verificará si la configuración es técnicamente
# válida. OPA verificará después si cumple las políticas
# organizacionales.
# ============================================================

variable "server_name" {
  type    = string
  default = "web-server"
}

variable "ssh_port" {
  type    = number
  default = 22
}

variable "ssh_source" {
  type    = string

  # Configuración insegura intencional para la demostración
  default = "10.0.0.0/24"
}

variable "encrypted" {
  type = bool

  # Configuración insegura intencional para la demostración
  default = true
}

variable "owner" {
  type    = string
  default = "Equipo Arquitectura"
}

variable "environment" {
  type    = string
  default = "DEV"
}

locals {
  server = {
    name        = var.server_name
    ssh_port    = var.ssh_port
    ssh_source  = var.ssh_source
    encrypted   = var.encrypted
    owner       = var.owner
    environment = var.environment
  }
}

output "server_configuration" {
  description = "Configuracion del servidor propuesta para despliegue"
  value       = local.server
}