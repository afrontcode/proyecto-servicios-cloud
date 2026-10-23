# Contenerización y Persistencia — Proyecto FinOps AWS

## Descripción

Este proyecto implementa un laboratorio cloud en Amazon Web Services (AWS) para consultar el estado de los recursos EC2, ejecutar diagnósticos y almacenar información relacionada con la infraestructura y sus costos.

La solución utiliza Docker y Docker Compose para la contenerización de los servicios, PostgreSQL para la persistencia de datos y Grafana para la visualización de métricas. Además, contempla el uso de Terraform para el aprovisionamiento de infraestructura como código (IaC).

## Arquitectura

El proyecto contempla dos entornos de ejecución:

- **Entorno local:** ejecución de los servicios mediante Docker Compose para desarrollo y pruebas.
- **Entorno AWS:** despliegue temporal en instancias EC2 dentro de una VPC, con separación entre la capa de aplicación y la capa de datos.

### Tecnologías utilizadas

| Tecnología | Descripción |
|---|---|
| Python 3.11 | Aplicación principal y lógica de diagnóstico |
| Docker | Contenerización de servicios |
| Docker Compose | Ejecución de múltiples contenedores |
| PostgreSQL 16 | Persistencia de datos |
| Grafana | Visualización de métricas y costos |
| Amazon EC2 | Infraestructura de cómputo |
| Amazon VPC | Segmentación de red |
| AWS Systems Manager | Administración segura de instancias |
| Terraform | Aprovisionamiento de infraestructura como código |

## Funcionamiento

1. El usuario accede a la aplicación FinOps.
2. La aplicación consulta el estado y la información de los recursos EC2.
3. Los resultados de diagnóstico y las configuraciones se almacenan en PostgreSQL.
4. Grafana permite visualizar las métricas disponibles mediante dashboards.
5. En AWS, la aplicación y la base de datos se comunican a través de una conexión privada.

## Requisitos previos

- Git.
- Docker.
- Docker Compose.
- Python 3.11, si se ejecuta la aplicación fuera de Docker.
- Terraform, para el despliegue de infraestructura.
- Una cuenta de AWS con los permisos necesarios para los recursos utilizados.

## Instalación y ejecución local

### 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPOSITORIO>
cd <NOMBRE_DEL_REPOSITORIO>
```

### 2. Configurar las variables de entorno

Configurar las variables requeridas por la aplicación y PostgreSQL según los archivos de configuración del proyecto.

No almacenar credenciales ni claves de AWS directamente en el repositorio.

### 3. Construir e iniciar los contenedores

```bash
docker compose up -d --build
```

### 4. Verificar los servicios

```bash
docker compose ps
```

### 5. Consultar los logs

```bash
docker compose logs -f
```

### 6. Detener los servicios

```bash
docker compose down
```

> Los comandos anteriores presuponen que existe un archivo Compose compatible en la raíz del repositorio.

## Despliegue en AWS

La arquitectura de despliegue contempla:

- Una VPC con subredes públicas y privadas.
- Una instancia EC2 para la aplicación.
- Una instancia EC2 para PostgreSQL.
- Security Groups para controlar el tráfico de red.
- IAM para la gestión de permisos.
- AWS Systems Manager para la administración de las instancias.
- Volúmenes EBS para el almacenamiento persistente.
