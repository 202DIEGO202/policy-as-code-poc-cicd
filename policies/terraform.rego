package terraform.security

import rego.v1

server := input.planned_values.outputs.server_configuration.value


# ============================================================
# SEC-INF-001 - BLOQUEANTE
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
# SEC-INF-002 - BLOQUEANTE
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


# ============================================================
# SEC-INF-003 - ADVERTENCIA
# Convención recomendada para nombre del servidor
# ============================================================

warning contains violation if {
    not startswith(server.name, "Demo-")

    violation := {
        "id": "SEC-INF-003",
        "severity": "MEDIUM",
        "message": "El nombre del servidor debería comenzar con el prefijo corporativo 'Demo-'"
    }
}


# ============================================================
# POLICY GATE
# Solo los DENY bloquean
# ============================================================

allow if {
    count(deny) == 0
}