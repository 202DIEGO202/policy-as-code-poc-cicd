package terraform.security

import rego.v1


# ============================================================
# RECURSOS AWS DEL TERRAFORM PLAN
# ============================================================
#
# OPA recibe el tfplan.json generado por:
#
# terraform show -json tfplan
#
# Los recursos que Terraform pretende crear se encuentran en:
#
# input.planned_values.root_module.resources
#
# En nuestro PoC esperamos:
#
# aws_vpc.main
# aws_subnet.web
# aws_security_group.web
# aws_instance.web
#
# ============================================================


# ============================================================
# SEC-INF-001 - BLOQUEANTE - HIGH
#
# No permitir SSH (puerto 22) abierto a todo Internet.
#
# Busca recursos aws_security_group dentro del Terraform Plan,
# recorre sus reglas ingress y detecta:
#
# puerto 22 + 0.0.0.0/0
# ============================================================

deny contains violation if {

    some resource in input.planned_values.root_module.resources

    resource.type == "aws_security_group"

    some ingress in resource.values.ingress

    ingress.from_port == 22
    ingress.to_port == 22

    "0.0.0.0/0" in ingress.cidr_blocks

    violation := {
        "id": "SEC-INF-001",
        "severity": "HIGH",
        "resource": resource.address,
        "message": "SSH puerto 22 no puede estar expuesto a Internet (0.0.0.0/0)"
    }
}


# ============================================================
# SEC-INF-002 - BLOQUEANTE - HIGH
#
# El disco principal EBS de una EC2 debe estar cifrado.
#
# Busca recursos aws_instance y verifica la propiedad
# root_block_device.encrypted.
# ============================================================

deny contains violation if {

    some resource in input.planned_values.root_module.resources

    resource.type == "aws_instance"

    some disk in resource.values.root_block_device

    disk.encrypted == false

    violation := {
        "id": "SEC-INF-002",
        "severity": "HIGH",
        "resource": resource.address,
        "message": "El volumen EBS principal de la instancia EC2 debe tener cifrado habilitado"
    }
}


# ============================================================
# SEC-INF-003 - ADVERTENCIA - MEDIUM
#
# Convención corporativa de nombres.
#
# Las instancias EC2 deberían tener un Tag Name que comience
# con el prefijo "Demo-".
#
# Esta política NO bloquea el pipeline.
# ============================================================

warning contains violation if {

    some resource in input.planned_values.root_module.resources

    resource.type == "aws_instance"

    name := resource.values.tags.Name

    not startswith(name, "Demo-")

    violation := {
        "id": "SEC-INF-003",
        "severity": "MEDIUM",
        "resource": resource.address,
        "message": "El nombre de la instancia EC2 debería comenzar con el prefijo corporativo 'Demo-'"
    }
}


# ============================================================
# POLICY GATE
#
# El despliegue solamente está permitido cuando no existen
# políticas DENY.
#
# Los WARNING se muestran, pero NO bloquean.
# ============================================================

allow if {
    count(deny) == 0
}