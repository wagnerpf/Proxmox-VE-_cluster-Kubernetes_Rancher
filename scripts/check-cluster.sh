#!/bin/bash

# Script para verificar o status do cluster Kubernetes usando Ansible

set -e

echo "=== Verificando status do cluster Kubernetes ==="

# Verificar se inventário do Ansible existe
if [ ! -f "ansible/inventory" ]; then
    echo "❌ Arquivo de inventário do Ansible não encontrado."
    echo "Execute primeiro: terraform apply"
    exit 1
fi

echo "Executando verificação via Ansible..."

cd ansible
ansible-playbook -i inventory check-cluster.yml

echo ""
echo "=== Verificação concluída ==="
