#!/bin/bash

# Script de validação pós-instalação do cluster Kubernetes
# Executa após o ansible-playbook

set -e

echo "🔍 Validando cluster Kubernetes..."

# Verificar se inventory existe
if [ ! -f "ansible/inventory" ]; then
    echo "❌ Arquivo inventory não encontrado"
    exit 1
fi

# Extrair IP do master
MASTER_IP=$(grep ansible_host ansible/inventory | head -1 | awk '{print $2}' | cut -d'=' -f2)
MASTER_USER=$(grep ansible_user ansible/inventory | head -1 | awk '{print $3}' | cut -d'=' -f2)
SSH_KEY="~/.ssh/k8s-cluster-key"

echo "🎯 Master: $MASTER_USER@$MASTER_IP"

# Função para executar comandos no master
run_on_master() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$MASTER_USER@$MASTER_IP" "$1"
}

# 1. Verificar conectividade SSH
echo "🔐 Verificando conectividade SSH..."
if run_on_master "echo 'SSH OK'" &>/dev/null; then
    echo "✅ SSH funcionando"
else
    echo "❌ Falha na conectividade SSH"
    exit 1
fi

# 2. Verificar status dos nós
echo "🖥️  Verificando nós do cluster..."
NODES=$(run_on_master "kubectl get nodes --no-headers 2>/dev/null | wc -l" || echo "0")
echo "Nós encontrados: $NODES"

if [ "$NODES" -ge 3 ]; then
    echo "✅ Cluster com $NODES nós"
    run_on_master "kubectl get nodes"
else
    echo "⚠️  Cluster incompleto ou não inicializado"
fi

# 3. Verificar pods do sistema
echo "🏗️  Verificando pods do sistema..."
SYSTEM_PODS=$(run_on_master "kubectl get pods -n kube-system --no-headers 2>/dev/null | grep Running | wc -l" || echo "0")
echo "Pods do sistema em execução: $SYSTEM_PODS"

if [ "$SYSTEM_PODS" -ge 8 ]; then
    echo "✅ Pods do sistema funcionando"
else
    echo "⚠️  Alguns pods podem não estar funcionando"
    run_on_master "kubectl get pods -n kube-system" || true
fi

# 4. Verificar recursos do cluster
echo "📊 Recursos do cluster..."
run_on_master "kubectl top nodes 2>/dev/null" || echo "⚠️  Metrics server não disponível"

# 5. Teste de conectividade interna
echo "🔗 Testando conectividade interna..."
if run_on_master "kubectl run test-pod --image=nginx --restart=Never --rm -i --timeout=60s -- echo 'Test OK'" &>/dev/null; then
    echo "✅ Conectividade interna funcionando"
else
    echo "⚠️  Problema na conectividade interna"
fi

echo ""
echo "🎉 Validação concluída!"
echo ""
echo "📋 Resumo do cluster:"
echo "   • Nós: $NODES"
echo "   • Pods sistema: $SYSTEM_PODS"
echo "   • API: https://$MASTER_IP:6443"
echo ""
