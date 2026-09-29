package terraform.security

import rego.v1

# Obtenemos la configuración propuesta por Terraform
server := input.planned_values.outputs.server_configuration.value

# ============================================================
# SEC-INF-001
# No permitir SSH abierto a todo Internet
# ============================================================

deny contains violation if {
    server.ssh_port == 22
    server.ssh_source == "0.0.0.0/0"

    violation := {
        "id": "SEC-INF-001",
        "severity": "HIGH",
        "message": "SSH puerto 22 no puede estar expuesto a Internet (0.0.0.0/0)"
    }
}

# ============================================================
# SEC-INF-002
# El cifrado debe estar habilitado
# ============================================================

deny contains violation if {
    server.encrypted == false

    violation := {
        "id": "SEC-INF-002",
        "severity": "HIGH",
        "message": "El servidor debe tener cifrado habilitado"
    }
}