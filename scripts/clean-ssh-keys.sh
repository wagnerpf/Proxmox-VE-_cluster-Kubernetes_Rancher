#!/bin/bash

# Limpa entradas do known_hosts para os IPs das VMs do cluster
# Útil quando as VMs são destruídas/recriadas com os mesmos IPs

set -e

INVENTORY="ansible/inventory"

echo "🔑 Limpando known_hosts das VMs do cluster..."

if [ ! -f "$INVENTORY" ]; then
    echo "⚠️  $INVENTORY não encontrado - nada para limpar"
    exit 0
fi

for ip in $(grep ansible_host "$INVENTORY" | sed -E "s/.*ansible_host=['\"]?([0-9.]+)['\"]?.*/\1/"); do
    ssh-keygen -R "$ip" 2>/dev/null && echo "   Removido: $ip"
done

echo "✅ known_hosts limpo"
