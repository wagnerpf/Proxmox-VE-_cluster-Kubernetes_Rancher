#!/bin/bash

# Mostra o status detalhado do Longhorn Storage

set -e

echo "📊 Status do Longhorn Storage"
echo "=============================="
echo

echo "🐄 NAMESPACE:"
if kubectl get namespace longhorn-system &> /dev/null; then
    echo "✅ Namespace longhorn-system existe"
else
    echo "❌ Namespace longhorn-system não encontrado"
    echo "💡 Execute './scripts/install-longhorn.sh' para instalar"
    exit 0
fi
echo

echo "💾 STORAGE CLASSES:"
kubectl get storageclass | grep -E "(NAME|longhorn|default)" || echo "❌ Storage class longhorn não encontrada"
echo

echo "🏃 PODS:"
kubectl get pods -n longhorn-system --no-headers | head -10 || echo "❌ Nenhum pod encontrado"
if [ "$(kubectl get pods -n longhorn-system --no-headers | wc -l)" -gt 10 ]; then
    echo "   ... e mais pods (total: $(kubectl get pods -n longhorn-system --no-headers | wc -l))"
fi
echo

echo "📦 VOLUMES:"
kubectl get volumes.longhorn.io -n longhorn-system --no-headers 2>/dev/null | wc -l | xargs echo "   Total de volumes:" || echo "   Volumes: Verificando..."
echo

echo "💡 ACESSO:"
echo "   Interface Web: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
echo "   Teste básico: ./scripts/test-longhorn.sh"
