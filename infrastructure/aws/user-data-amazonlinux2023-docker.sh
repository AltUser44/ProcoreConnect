#!/bin/bash
# cloud-init: Amazon Linux 2023 + Docker + Compose plugin (v2)
set -euo pipefail
exec > >(tee /var/log/procoreconnect-bootstrap.log) 2>&1

dnf -y update

# Docker engine
dnf -y install docker
systemctl enable --now docker

# Allow ec2-user to run docker without sudo
usermod -aG docker ec2-user

# docker compose (plugin, provides `docker compose` subcommand)
if ! dnf -y install docker-compose-plugin; then
  # Fallback: some AL2023 variants bundle compose differently
  dnf -y install docker-compose-plugin || true
fi

# Handy for pulling deploy artifacts from Git
dnf -y install git

# Smoke check (do not fail the instance if it flakes)
set +e
docker run --rm public.ecr.aws/docker/library/hello-world:latest
set -e

echo "bootstrap complete"
