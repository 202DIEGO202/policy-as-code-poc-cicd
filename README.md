# Policy as Code con OPA y Terraform

Prueba de concepto para validar infraestructura como código antes del despliegue. Terraform genera un plan de cambios, Open Policy Agent (OPA) evalúa su representación JSON mediante políticas escritas en Rego y un *Policy Gate* decide si el flujo puede continuar.

La demostración se limita a crear y evaluar el plan. No ejecuta `terraform apply` ni crea recursos en AWS.

## Objetivo

El proyecto demuestra cómo convertir controles de seguridad y estándares técnicos en decisiones automáticas dentro de un flujo de integración continua. La validación permite:

- Detectar configuraciones inseguras antes del despliegue.
- Diferenciar incumplimientos que bloquean de advertencias informativas.
- Evaluar el mismo plan que Terraform preparó para aplicar.
- Registrar evidencia automática en GitHub Actions.
- Evitar la creación de recursos cuando existe una infracción crítica.

## Arquitectura de la prueba

```text
Terraform ──> tfplan ──> tfplan.json ──> OPA + Rego ──> Policy Gate ──> GitHub Actions
   IaC          plan         entrada        evaluación       control          evidencia
```

1. Terraform define la infraestructura y genera un plan binario.
2. El plan se convierte a JSON.
3. OPA recibe el JSON y evalúa las políticas Rego.
4. El *Policy Gate* clasifica los hallazgos como `DENY` o `WARNING`.
5. GitHub Actions muestra el resultado y detiene el flujo si encuentra al menos un `DENY`.

## Infraestructura evaluada

La configuración de ejemplo representa los siguientes recursos de AWS:

- VPC.
- Subred.
- Grupo de seguridad.
- Instancia EC2.
- Volumen EBS.

## Políticas

| ID | Condición evaluada | Severidad | Decisión |
| --- | --- | --- | --- |
| `SEC-INF-001` | Puerto SSH 22 abierto a `0.0.0.0/0` | Alta | `DENY` |
| `SEC-INF-002` | Volumen EBS con `encrypted = false` | Alta | `DENY` |
| `SEC-INF-003` | Nombre de la instancia EC2 sin el prefijo `Demo` | Media | `WARNING` |

Las decisiones `DENY` detienen el workflow. Las decisiones `WARNING` quedan visibles como evidencia, pero no causan el fallo por sí solas.

## Tecnologías

| Tecnología | Función |
| --- | --- |
| Terraform y HCL | Definición de infraestructura y generación del plan |
| AWS | Tipos de recursos representados en el plan |
| Open Policy Agent | Evaluación de las decisiones de política |
| Rego | Definición de las reglas |
| JSON | Intercambio del plan entre Terraform y OPA |
| GitHub Actions y YAML | Automatización del flujo y aplicación del *Policy Gate* |

## Requisitos

Para ejecutar la prueba localmente se necesita:

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Open Policy Agent](https://www.openpolicyagent.org/docs/latest/#running-opa)
- Git
- Una terminal compatible con los comandos de Terraform y OPA

No se requieren credenciales de AWS para generar y revisar el plan cuando la configuración evita consultas que dependan de una cuenta. Si se agregan proveedores de datos o validaciones remotas, Terraform podría solicitar credenciales.

## Ejecución local

### 1. Inicializar y validar Terraform

```bash
terraform init
terraform fmt -check
terraform validate
```

### 2. Generar el plan sin desplegar recursos

```bash
terraform plan -out=tfplan
```

### 3. Convertir el plan a JSON

```bash
terraform show -json tfplan > tfplan.json
```

### 4. Evaluar las políticas

```bash
opa eval \
  --data policies/ \
  --input tfplan.json \
  "data"
```

El comando carga todas las políticas del directorio `policies/` y muestra las decisiones disponibles. Si el repositorio define un paquete o una regla de entrada específica, se puede reemplazar `data` por su ruta, por ejemplo `data.terraform.analysis`.

> Los archivos `tfplan` y `tfplan.json` pueden contener información sensible. No deben publicarse ni versionarse.

## Ejecución en GitHub Actions

El workflow automatiza estas etapas:

1. Descarga el código.
2. Instala Terraform y OPA.
3. Inicializa y valida la configuración.
4. Genera `tfplan` y `tfplan.json`.
5. Evalúa las políticas Rego.
6. Publica los hallazgos.
7. Devuelve código de salida `1` si existe un `DENY`.

La rama de trabajo usada para la entrega es `policy-as-code`.

## Resultados de la prueba

La primera ejecución produjo el siguiente resultado:

| Indicador | Resultado | Interpretación |
| --- | ---: | --- |
| Decisiones `DENY` | 2 | El flujo debía bloquearse |
| Decisiones `WARNING` | 1 | La advertencia debía quedar visible |
| Código de salida | 1 | La automatización informó un fallo de política |
| Recursos creados en AWS | 0 | El control actuó antes del despliegue |

Después de cerrar la exposición pública de SSH, activar el cifrado del volumen y ajustar el nombre de la instancia, el resultado esperado es cero decisiones `DENY` y código de salida `0`.

## Estructura recomendada

```text
.
├── .github/
│   └── workflows/
│       └── policy-as-code.yml
├── policies/
│   ├── network.rego
│   ├── storage.rego
│   └── naming.rego
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── versions.tf
├── .gitignore
└── README.md
```

Los nombres pueden ajustarse a la estructura real del repositorio. Conviene mantener separadas la infraestructura, las políticas y la automatización.

## Seguridad del repositorio

No se deben versionar:

- Credenciales o claves de acceso.
- Archivos `.tfstate` y sus copias de respaldo.
- Planes binarios `tfplan`.
- Planes convertidos a `tfplan.json`.
- Archivos de variables que contengan secretos.

Ejemplo mínimo para `.gitignore`:

```gitignore
.terraform/
*.tfstate
*.tfstate.*
*.tfplan
tfplan
tfplan.json
*.tfvars
*.tfvars.json
crash.log
```

Conviene versionar `.terraform.lock.hcl` en proyectos de infraestructura para mantener consistentes las versiones seleccionadas de los proveedores.

## Buenas prácticas para evolucionar la PoC

- Asignar a cada política un responsable, una severidad y una fecha de revisión.
- Probar las reglas con casos permitidos y denegados antes de activarlas.
- Introducir como advertencia las reglas cuyo impacto todavía no se conoce bien.
- Definir excepciones con justificación, aprobador y fecha de vencimiento.
- Mantener estados y credenciales separados por ambiente.
- Usar credenciales temporales, por ejemplo mediante OIDC en GitHub Actions.
- Promover las políticas entre desarrollo, pruebas, preproducción y producción mediante un proceso controlado.

## Alcance y limitaciones

Esta prueba valida el control preventivo sobre un plan de Terraform. No busca desplegar una arquitectura completa, medir el rendimiento de distintos motores ni sustituir otros controles de seguridad. La calidad de la decisión depende de que OPA reciba datos completos y de que las políticas se mantengan actualizadas.

## Referencias

- [Documentación de Open Policy Agent](https://www.openpolicyagent.org/docs/latest/)
- [Lenguaje Rego](https://www.openpolicyagent.org/docs/latest/policy-language/)
- [Open Policy Agent en CNCF](https://www.cncf.io/projects/open-policy-agent-opa/)
- [Documentación de Terraform](https://developer.hashicorp.com/terraform/docs)
- [GitHub Actions](https://docs.github.com/actions)

## Autor

**Diego Alejandro Paz Gómez**

Proyecto académico sobre arquitectura de software y Policy as Code.
