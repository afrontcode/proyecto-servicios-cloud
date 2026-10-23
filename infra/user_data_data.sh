#!/bin/bash
# Arranque de finops-data: Docker + volumen EBS persistente para PostgreSQL.
# Todo queda registrado en /var/log/user-data.log para poder depurarlo por SSM.
exec > >(tee -a /var/log/user-data.log) 2>&1
set -x

dnf update -y
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# --- Volumen de datos ---
# En instancias Nitro el disco real es /dev/nvmeXn1; Amazon Linux crea el
# symlink /dev/sdf. El attachment puede tardar en completarse tras el boot.
DISPOSITIVO=/dev/sdf
PUNTO_MONTAJE=/mnt/pgdata

for _ in $(seq 1 60); do
  [ -e "$DISPOSITIVO" ] && break
  sleep 3
done

if [ ! -e "$DISPOSITIVO" ]; then
  echo "ERROR: el volumen $DISPOSITIVO nunca apareció. Nada que montar."
  exit 0
fi

REAL=$(readlink -f "$DISPOSITIVO")

# Formatear SOLO si no tiene sistema de archivos. Nunca se reformatea un disco
# con datos: así un reinicio o un re-apply no borra la base de datos.
if ! blkid "$REAL" >/dev/null 2>&1; then
  echo "Volumen vacío, creando sistema de archivos XFS"
  mkfs -t xfs "$REAL"
else
  echo "El volumen ya tiene sistema de archivos, se conserva"
fi

mkdir -p "$PUNTO_MONTAJE"

# Montaje por UUID: sobrevive a cambios de nombre de dispositivo.
# 'nofail' evita que un volumen ausente impida arrancar la instancia.
UUID=$(blkid -s UUID -o value "$REAL")
if ! grep -q "$UUID" /etc/fstab; then
  echo "UUID=$UUID $PUNTO_MONTAJE xfs defaults,nofail 0 2" >> /etc/fstab
fi
mount -a

# PostgreSQL del contenedor corre con UID 999
mkdir -p "$PUNTO_MONTAJE/data"
chown -R 999:999 "$PUNTO_MONTAJE/data"

echo "finops-data listo. Volumen montado en $PUNTO_MONTAJE:"
df -h "$PUNTO_MONTAJE"
