# Imagen de la aplicación FinOps (scripts boto3 + verificación de conectividad).
# Build multi-stage: los compiladores y la caché de pip se quedan en la etapa 1
# y nunca llegan a la imagen final.

# ---------- Etapa 1: construcción de dependencias ----------
FROM python:3.11-slim AS builder

ENV PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Entorno virtual aislado: luego se copia entero a la imagen final
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /build
COPY requirements.txt .
RUN pip install -r requirements.txt

# ---------- Etapa 2: imagen final ----------
FROM python:3.11-slim

ENV PATH="/opt/venv/bin:$PATH" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

# Usuario sin privilegios. UID 1000 para que coincida con el del host y pueda
# leer las credenciales de AWS montadas de solo lectura.
RUN useradd --create-home --uid 1000 finops

COPY --from=builder /opt/venv /opt/venv

WORKDIR /app
COPY --chown=finops:finops config/ ./config/
COPY --chown=finops:finops src/ ./src/

USER finops

# Verifica cada 30 s que alcanza PostgreSQL y AWS, y lo deja en los logs.
CMD ["python", "-m", "src.healthcheck"]
