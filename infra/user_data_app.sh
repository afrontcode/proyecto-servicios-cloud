#!/bin/bash
# Arranque de finops-app: Docker + plugin compose para levantar la app y Grafana.
exec > >(tee -a /var/log/user-data.log) 2>&1
set -x

dnf update -y
dnf install -y docker git
systemctl enable --now docker
usermod -aG docker ec2-user

# Plugin compose v2 (AL2023 no lo trae en sus repos)
DIR_PLUGINS=/usr/libexec/docker/cli-plugins
mkdir -p "$DIR_PLUGINS"
curl -fsSL -o "$DIR_PLUGINS/docker-compose" \
  "https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64"
chmod +x "$DIR_PLUGINS/docker-compose"

echo "finops-app listo:"
docker --version
docker compose version
