#!/bin/bash

# Script para instalação do Longhorn Storage
# Parte do projeto Kubernetes Proxmox VE

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

# Verificar pré-requisitos
check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    
    # Verificar kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl não encontrado. Instale kubectl primeiro."
        exit 1
    fi
    
    # Verificar conectividade com cluster
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Não foi possível conectar ao cluster Kubernetes."
        log_info "Certifique-se de que:"
        log_info "  1. O cluster está rodando"
        log_info "  2. O kubeconfig está configurado"
        log_info "  3. Execute 'make validate' para verificar o cluster"
        exit 1
    fi
    
    # Verificar nós do cluster
    local nodes_ready=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    if [ "$nodes_ready" -lt 2 ]; then
        log_warning "Apenas $nodes_ready nó(s) prontos. Longhorn recomenda pelo menos 3 nós para HA."
        log_info "Continuando a instalação mesmo assim..."
    else
        log_success "Cluster com $nodes_ready nós prontos - ideal para Longhorn"
    fi
}

# Verificar se Longhorn já está instalado
check_existing_installation() {
    log_info "Verificando instalação existente do Longhorn..."
    
    if kubectl get namespace longhorn-system &> /dev/null; then
        log_warning "Namespace longhorn-system já existe"
        
        # Verificar se há pods do Longhorn rodando
        local longhorn_pods=$(kubectl get pods -n longhorn-system --no-headers 2>/dev/null | wc -l)
        if [ "$longhorn_pods" -gt 0 ]; then
            log_warning "Longhorn parece já estar instalado ($longhorn_pods pods encontrados)"
            echo
            read -p "Deseja reinstalar o Longhorn? [y/N]: " reinstall
            if [[ ! $reinstall =~ ^[Yy]$ ]]; then
                log_info "Abortando instalação"
                exit 0
            fi
            
            log_info "Removendo instalação existente..."
            kubectl delete namespace longhorn-system --ignore-not-found=true
            log_info "Aguardando remoção completa..."
            while kubectl get namespace longhorn-system &> /dev/null; do
                echo -n "."
                sleep 2
            done
            echo
        fi
    fi
}

# Instalar Longhorn
install_longhorn() {
    log_info "Instalando Longhorn Storage..."
    
    # Baixar e aplicar manifests
    log_info "Baixando manifests do Longhorn v1.5.3..."
    if ! kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/v1.5.3/deploy/longhorn.yaml; then
        log_error "Falha ao aplicar manifests do Longhorn"
        exit 1
    fi
    
    log_success "Manifests aplicados com sucesso"
}

# Aguardar pods ficarem prontos
wait_for_pods() {
    log_info "Aguardando pods do Longhorn ficarem prontos..."
    log_info "Isso pode levar alguns minutos..."
    
    # Aguardar namespace ser criado
    local timeout=60
    local count=0
    while ! kubectl get namespace longhorn-system &> /dev/null; do
        if [ $count -ge $timeout ]; then
            log_error "Timeout aguardando namespace longhorn-system"
            exit 1
        fi
        echo -n "."
        sleep 1
        count=$((count + 1))
    done
    echo
    
    log_info "Namespace criado, aguardando pods..."
    
    # Aguardar pods críticos
    log_info "Aguardando longhorn-manager pods..."
    if ! kubectl wait --for=condition=ready pod -l app=longhorn-manager -n longhorn-system --timeout=600s; then
        log_error "Timeout aguardando longhorn-manager pods"
        log_info "Verificando status dos pods:"
        kubectl get pods -n longhorn-system
        exit 1
    fi
    
    log_info "Aguardando longhorn-driver-deployer..."
    if ! kubectl wait --for=condition=ready pod -l app=longhorn-driver-deployer -n longhorn-system --timeout=300s; then
        log_warning "longhorn-driver-deployer pode ainda estar inicializando"
    fi
    
    log_success "Pods principais do Longhorn estão prontos"
}

# Configurar storage class padrão
configure_default_storage_class() {
    log_info "Configurando Longhorn como storage class padrão..."
    
    # Aguardar storage class ser criada
    local timeout=60
    local count=0
    while ! kubectl get storageclass longhorn &> /dev/null; do
        if [ $count -ge $timeout ]; then
            log_error "Storage class 'longhorn' não foi criada"
            exit 1
        fi
        echo -n "."
        sleep 1
        count=$((count + 1))
    done
    echo
    
    # Remover padrão das storage classes existentes
    log_info "Removendo marcação de padrão de outras storage classes..."
    kubectl get storageclass -o name | while read sc; do
        kubectl annotate $sc storageclass.kubernetes.io/is-default-class- 2>/dev/null || true
    done
    
    # Definir Longhorn como padrão
    log_info "Definindo Longhorn como storage class padrão..."
    if kubectl annotate storageclass longhorn storageclass.kubernetes.io/is-default-class=true; then
        log_success "Longhorn configurado como storage class padrão"
    else
        log_warning "Falha ao configurar Longhorn como padrão - configure manualmente se necessário"
    fi
}

# Verificar instalação
verify_installation() {
    log_info "Verificando instalação do Longhorn..."
    
    echo
    echo "=== STATUS DAS STORAGE CLASSES ==="
    kubectl get storageclass
    
    echo
    echo "=== STATUS DOS PODS LONGHORN ==="
    kubectl get pods -n longhorn-system
    
    echo
    echo "=== STATUS DOS NODES LONGHORN ==="
    kubectl get nodes.longhorn.io -n longhorn-system 2>/dev/null || log_info "Nodes do Longhorn ainda inicializando..."
    
    # Verificar se pelo menos um pod está rodando
    local running_pods=$(kubectl get pods -n longhorn-system --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    if [ "$running_pods" -gt 0 ]; then
        log_success "Longhorn instalado com sucesso! ($running_pods pods rodando)"
        return 0
    else
        log_warning "Longhorn pode ainda estar inicializando"
        return 1
    fi
}

# Mostrar informações de acesso
show_access_info() {
    log_info "Informações de acesso ao Longhorn:"
    echo
    echo "🌐 INTERFACE WEB:"
    echo "   Para acessar a interface web do Longhorn, execute:"
    echo "   kubectl port-forward -n longhorn-system svc/longhorn-frontend 8080:80"
    echo "   Em seguida, acesse: http://localhost:8080"
    echo
    echo "🔧 INGRESS (Opcional):"
    echo "   Para acesso permanente, configure um Ingress:"
    echo "   Host sugerido: longhorn.<SEU_MASTER_IP>.nip.io"
    echo
    echo "📝 USO EM APLICAÇÕES:"
    echo "   Para usar volumes persistentes, especifique:"
    echo "   storageClassName: longhorn"
    echo
    echo "📚 DOCUMENTAÇÃO:"
    echo "   https://longhorn.io/docs/"
}

# Criar script de teste
create_test_script() {
    local test_script="scripts/test-longhorn.sh"
    
    log_info "Criando script de teste: $test_script"
    
    cat > "$test_script" << 'EOF'
#!/bin/bash

# Teste básico do Longhorn Storage

set -e

echo "🧪 Testando Longhorn Storage..."

# Criar PVC de teste
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-test-pvc
  labels:
    test: longhorn
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
YAML

echo "✅ PVC criado"

# Aguardar PVC ser bound
echo "⏳ Aguardando PVC ser bound..."
kubectl wait --for=condition=bound pvc/longhorn-test-pvc --timeout=300s

# Criar pod de teste
cat << 'YAML' | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: longhorn-test-pod
  labels:
    test: longhorn
spec:
  containers:
  - name: test
    image: alpine:latest
    command: ["/bin/sh", "-c"]
    args:
    - |
      echo "Testando escrita no volume..." > /data/test.txt
      echo "Conteúdo escrito com sucesso!" >> /data/test.txt
      cat /data/test.txt
      echo "Dormindo por 30 segundos..."
      sleep 30
    volumeMounts:
    - name: test-storage
      mountPath: /data
  volumes:
  - name: test-storage
    persistentVolumeClaim:
      claimName: longhorn-test-pvc
  restartPolicy: Never
YAML

echo "✅ Pod de teste criado"

# Aguardar pod completar
echo "⏳ Aguardando teste completar..."
kubectl wait --for=condition=ready pod/longhorn-test-pod --timeout=120s
kubectl logs -f longhorn-test-pod

# Limpeza
echo "🧹 Limpando recursos de teste..."
kubectl delete pod longhorn-test-pod --ignore-not-found=true
kubectl delete pvc longhorn-test-pvc --ignore-not-found=true

echo "✅ Teste do Longhorn concluído com sucesso!"
EOF

    chmod +x "$test_script"
    log_success "Script de teste criado: $test_script"
}

# Função principal
main() {
    echo "🐄 Instalação do Longhorn Storage"
    echo "=================================="
    echo
    
    check_prerequisites
    check_existing_installation
    install_longhorn
    wait_for_pods
    configure_default_storage_class
    
    echo
    if verify_installation; then
        echo
        show_access_info
        create_test_script
        
        echo
        log_success "🎉 Longhorn instalado com sucesso!"
        log_info "Execute 'make test-longhorn' para testar a instalação"
    else
        echo
        log_warning "Instalação pode estar incompleta"
        log_info "Execute 'kubectl get pods -n longhorn-system' para verificar"
        log_info "Execute 'make test-longhorn' para testar quando estiver pronto"
    fi
}

# Executar apenas se chamado diretamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
