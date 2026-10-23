#!/usr/bin/env bash
# Muestra de un vistazo el estado del proyecto: local y en AWS.
# Uso:  ./scripts/ver-actividad.sh
set -uo pipefail

# Forzados a propósito: la SCP de la organización solo permite us-east-2, y el
# proyecto siempre usa este perfil. Así el script no depende de lo que tengas
# exportado en la terminal.
PERFIL=finops-demo
REGION=us-east-2
aws() { command aws --profile "$PERFIL" --region "$REGION" "$@"; }

APP=i-0983b8d7cd0be04ef
DATA=i-0ce92594563e7e299

# Ejecuta un comando dentro de una instancia por SSM y espera el resultado
en_instancia() {
  local inst=$1 cmd=$2 id estado salida
  id=$(aws ssm send-command --document-name AWS-RunShellScript \
       --instance-ids "$inst" --parameters "commands=[\"$cmd\"]" \
       --query Command.CommandId --output text 2>&1)
  if [[ "$id" == *rror* || "$id" == *denied* ]]; then
    echo "  ERROR: $id" | head -2
    return
  fi
  for _ in $(seq 1 20); do
    sleep 2
    estado=$(aws ssm get-command-invocation --command-id "$id" --instance-id "$inst" \
             --query Status --output text 2>/dev/null)
    [ "$estado" = "Success" ] || [ "$estado" = "Failed" ] && break
  done
  aws ssm get-command-invocation --command-id "$id" --instance-id "$inst" \
      --query StandardOutputContent --output text 2>&1 | sed 's/^/  /'
}

echo "=============== CONTENEDORES LOCALES ==============="
docker compose ps --format '  {{.Name}}\t{{.Status}}' 2>&1 || echo "  (stack local apagado)"

echo
echo "=============== INSTANCIAS EN AWS ==============="
salida=$(aws ec2 describe-instances --filters "Name=tag:Project,Values=finops-demo" \
  "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].{Nombre:Tags[?Key==`Name`]|[0].Value,Id:InstanceId,IPprivada:PrivateIpAddress,IPpublica:PublicIpAddress}' \
  --output table 2>&1)
echo "$salida"

echo "=============== APP EN AWS: ultimas lineas ==============="
en_instancia "$APP" "docker logs --tail 6 finops-app"

echo
echo "=============== DATOS EN POSTGRESQL (AWS) ==============="
en_instancia "$DATA" "docker exec finops-postgres psql -U finops -d finops -c 'SELECT id, nota, creado FROM prueba_persistencia;'"

echo
echo "Grafana local: http://localhost:3000  (admin/admin)"
