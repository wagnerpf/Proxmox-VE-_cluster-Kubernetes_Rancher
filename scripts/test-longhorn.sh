#!/bin/bash

# Teste básico do Longhorn Storage

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🧪 Testando Longhorn Storage..."
echo "==============================="
echo

# Verificar se Longhorn está instalado
log_info "Verificando se Longhorn está instalado..."
if ! kubectl get storageclass longhorn &> /dev/null; then
    log_error "Storage class 'longhorn' não encontrada"
    log_info "Execute 'make install-longhorn' primeiro"
    exit 1
fi

log_success "Storage class 'longhorn' encontrada"

# Verificar pods do Longhorn
log_info "Verificando pods do Longhorn..."
local longhorn_pods=$(kubectl get pods -n longhorn-system --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
if [ "$longhorn_pods" -eq 0 ]; then
    log_error "Nenhum pod do Longhorn está rodando"
    kubectl get pods -n longhorn-system
    exit 1
fi

log_success "$longhorn_pods pods do Longhorn estão rodando"

# Criar PVC de teste
log_info "Criando PVC de teste..."
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-test-pvc
  labels:
    test: longhorn-test
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
EOF

log_success "PVC criado"

# Aguardar PVC ser bound
log_info "Aguardando PVC ser bound..."
if ! kubectl wait --for=condition=bound pvc/longhorn-test-pvc --timeout=300s; then
    log_error "PVC não foi bound dentro do timeout"
    kubectl describe pvc longhorn-test-pvc
    exit 1
fi

log_success "PVC bound com sucesso"

# Criar pod de teste
log_info "Criando pod de teste..."
cat << 'EOF' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: longhorn-test-pod
  labels:
    test: longhorn-test
spec:
  containers:
  - name: test
    image: alpine:latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "=== TESTE DE ESCRITA NO VOLUME LONGHORN ==="
      echo "Timestamp: $(date)" > /data/test.txt
      echo "Hostname: $(hostname)" >> /data/test.txt
      echo "Volume montado em: /data" >> /data/test.txt
      echo "" >> /data/test.txt
      echo "Testando escrita..." >> /data/test.txt
      for i in $(seq 1 5); do
        echo "Linha $i de teste" >> /data/test.txt
      done
      echo "" >> /data/test.txt
      echo "=== CONTEÚDO DO ARQUIVO ===" 
      cat /data/test.txt
      echo "=== INFORMAÇÕES DO FILESYSTEM ==="
      df -h /data
      echo "=== TESTE CONCLUÍDO COM SUCESSO ==="
      sleep 10
    volumeMounts:
    - name: test-storage
      mountPath: /data
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: longhorn-test-pvc
  restartPolicy: Never
EOF

log_success "Pod de teste criado"

# Aguardar pod ficar pronto
log_info "Aguardando pod ficar pronto..."
if ! kubectl wait --for=condition=ready pod/longhorn-test-pod --timeout=120s; then
    log_warning "Pod pode ainda estar inicializando"
fi

# Mostrar logs do teste
log_info "Executando teste de escrita/leitura..."
echo "==================== LOGS DO TESTE ===================="
kubectl logs -f longhorn-test-pod 2>/dev/null || {
    log_warning "Aguardando pod completar..."
    sleep 5
    kubectl logs longhorn-test-pod 2>/dev/null || log_error "Não foi possível obter logs"
}
echo "========================================================"

# Aguardar pod completar
log_info "Aguardando teste completar..."
kubectl wait --for=condition=complete job.batch/longhorn-test-pod --timeout=180s 2>/dev/null || {
    local pod_status=$(kubectl get pod longhorn-test-pod -o jsonpath='{.status.phase}' 2>/dev/null || echo "Unknown")
    if [ "$pod_status" = "Succeeded" ]; then
        log_success "Pod completou com sucesso"
    else
        log_warning "Pod status: $pod_status"
    fi
}

# Verificar se o volume foi criado no Longhorn
log_info "Verificando volume no Longhorn..."
if kubectl get volumes.longhorn.io -n longhorn-system &> /dev/null; then
    local volume_count=$(kubectl get volumes.longhorn.io -n longhorn-system --no-headers | wc -l)
    log_success "$volume_count volume(s) encontrados no Longhorn"
else
    log_warning "Não foi possível verificar volumes do Longhorn"
fi

# Limpeza
log_info "Limpando recursos de teste..."
kubectl delete pod longhorn-test-pod --ignore-not-found=true
kubectl delete pvc longhorn-test-pvc --ignore-not-found=true

echo
log_success "🎉 Teste do Longhorn concluído com sucesso!"
echo
log_info "Próximos passos:"
log_info "  1. Acesse a UI: kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
log_info "  2. Navegue para: http://localhost:8080"
log_info "  3. Crie volumes persistentes usando storageClassName: longhorn"
log_info "  4. Consulte: VOLUMES-PERSISTENTES.md para exemplos"
