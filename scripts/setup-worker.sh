#!/bin/bash

# Script para configurar nós worker do Kubernetes

set -e

echo "=== Configurando nó worker do Kubernetes ==="

# O comando de join será fornecido pelo Terraform
# através do arquivo /tmp/join-command.sh

echo "=== Nó worker configurado com sucesso ==="
