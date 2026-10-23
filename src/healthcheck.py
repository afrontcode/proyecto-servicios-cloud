"""Verifica que el contenedor de la app alcanza PostgreSQL y AWS.

No es el scheduler (eso es la Fase 3): solo comprueba la conectividad entre
servicios y la deja registrada en los logs mientras el stack está levantado.

Uso:
    python -m src.healthcheck             # bucle, un chequeo cada 30 s
    python -m src.healthcheck --una-vez   # un chequeo y salir
"""
import argparse
import sys
import time
from datetime import datetime

import psycopg2

from config import settings
from src import aws_client

INTERVALO_SEGUNDOS = 30


def probar_postgres():
    """Conecta a PostgreSQL y devuelve (ok, detalle)."""
    try:
        conexion = psycopg2.connect(connect_timeout=5, **settings.POSTGRES)
        with conexion, conexion.cursor() as cursor:
            cursor.execute("SELECT version()")
            version = cursor.fetchone()[0].split(" on ")[0]
        conexion.close()
        return True, version
    except Exception as e:
        return False, str(e).strip().splitlines()[0]


def probar_aws():
    """Llama a STS para confirmar que las credenciales montadas sirven."""
    try:
        identidad = aws_client.client("sts").get_caller_identity()
        return True, f"{identidad['Arn'].split('/')[-1]} (cuenta {identidad['Account']})"
    except Exception as e:
        return False, f"{type(e).__name__}: {str(e).splitlines()[0][:90]}"


def chequear():
    """Ejecuta ambas pruebas y las imprime. Devuelve True si PostgreSQL responde."""
    marca = datetime.now().strftime("%H:%M:%S")
    destino = f"{settings.POSTGRES['host']}:{settings.POSTGRES['port']}"

    ok_db, detalle_db = probar_postgres()
    print(f"[{marca}] postgres {destino:<20} {'OK   ' if ok_db else 'FALLA'} {detalle_db}", flush=True)

    ok_aws, detalle_aws = probar_aws()
    print(f"[{marca}] aws      {settings.AWS_REGION:<20} {'OK   ' if ok_aws else 'FALLA'} {detalle_aws}", flush=True)

    return ok_db


def main():
    parser = argparse.ArgumentParser(description="Verifica la conectividad del contenedor de la app.")
    parser.add_argument("--una-vez", action="store_true", help="un solo chequeo y salir")
    parser.add_argument("--intervalo", type=int, default=INTERVALO_SEGUNDOS,
                        help=f"segundos entre chequeos (por defecto {INTERVALO_SEGUNDOS})")
    args = parser.parse_args()

    if args.una_vez:
        sys.exit(0 if chequear() else 1)

    print(f"Verificando conectividad cada {args.intervalo} s. Ctrl-C para salir.", flush=True)
    while True:
        chequear()
        time.sleep(args.intervalo)


if __name__ == "__main__":
    main()
