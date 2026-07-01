#!/bin/bash

# Script para criar template Ubuntu 22.04 em nós Proxmox VE
# Uso: ./create-template.sh [node1,node2,node3] ou ./create-template.sh single

set -e

TEMPLATE_ID=9000
TEMPLATE_NAME="ubuntu-22.04-cloud"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="jammy-server-cloudimg-amd64.img"

echo "🚀 Script de Criação de Template Ubuntu 22.04 para Proxmox VE"
echo "=============================================================="

# Função para criar template em um nó
create_template_on_node() {
    local node=$1
    echo "📦 Criando template no nó: $node"
    
    # Verificar se nó está acessível
    if ! ssh -o ConnectTimeout=5 root@$node "echo 'OK'" &>/dev/null; then
        echo "❌ Erro: Não foi possível conectar no nó $node"
        return 1
    fi
    
    # Verificar se template já existe
    if ssh root@$node "qm list | grep -q '$TEMPLATE_ID'"; then
        echo "⚠️  Template ID $TEMPLATE_ID já existe no nó $node"
        read -p "Deseja substituir? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "⏭️  Pulando nó $node"
            return 0
        fi
        echo "🗑️  Removendo template existente..."
        ssh root@$node "qm destroy $TEMPLATE_ID"
    fi
    
    echo "⬇️  Baixando imagem Ubuntu 24.04..."
    ssh root@$node << EOF
        cd /tmp
        rm -f $IMAGE_FILE
        wget -q --show-progress $IMAGE_URL
        
        echo "🔧 Criando VM base..."
        qm create $TEMPLATE_ID --name $TEMPLATE_NAME --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
        
        echo "💾 Importando disco..."
        qm importdisk $TEMPLATE_ID $IMAGE_FILE local-lvm
        
        echo "⚙️  Configurando VM..."
        qm set $TEMPLATE_ID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$TEMPLATE_ID-disk-0
        qm set $TEMPLATE_ID --boot c --bootdisk scsi0
        qm set $TEMPLATE_ID --scsi1 local-lvm:cloudinit
        qm set $TEMPLATE_ID --serial0 socket --vga serial0
        qm set $TEMPLATE_ID --agent enabled=1
        
        echo "📋 Convertendo para template..."
        qm template $TEMPLATE_ID
        
        echo "🧹 Limpando arquivos temporários..."
        rm -f $IMAGE_FILE
        
        echo "✅ Template $TEMPLATE_NAME criado com sucesso no nó \$(hostname)!"
EOF
    
    if [ $? -eq 0 ]; then
        echo "✅ Template criado com sucesso no nó: $node"
        return 0
    else
        echo "❌ Erro ao criar template no nó: $node"
        return 1
    fi
}

# Função para listar nós do cluster
list_cluster_nodes() {
    echo "🔍 Detectando nós do cluster..."
    
    # Tentar obter lista de nós automaticamente
    if command -v pvecm &> /dev/null; then
        NODES=$(pvecm nodes | grep "^[[:space:]]*[0-9]" | awk '{print $3}' | grep -v "^$")
        if [ ! -z "$NODES" ]; then
            echo "📋 Nós encontrados:"
            echo "$NODES" | nl -w2 -s'. '
            return 0
        fi
    fi
    
    echo "⚠️  Não foi possível detectar nós automaticamente"
    echo "💡 Execute este script em um nó do cluster ou forneça os nós manualmente"
    return 1
}

# Função para validar conectividade
validate_connectivity() {
    local nodes=("$@")
    echo "🔗 Validando conectividade com os nós..."
    
    local failed_nodes=()
    for node in "${nodes[@]}"; do
        if ssh -o ConnectTimeout=5 root@$node "echo 'OK'" &>/dev/null; then
            echo "✅ $node - OK"
        else
            echo "❌ $node - FALHA"
            failed_nodes+=("$node")
        fi
    done
    
    if [ ${#failed_nodes[@]} -gt 0 ]; then
        echo "⚠️  Nós com problemas de conectividade:"
        printf '%s\n' "${failed_nodes[@]}"
        echo "💡 Verifique SSH keys e conectividade de rede"
        return 1
    fi
    
    return 0
}

# Processamento dos argumentos
case "${1:-auto}" in
    "single")
        echo "🎯 Modo: Template em nó único"
        echo "💡 Detectando nó atual..."
        
        CURRENT_NODE=$(hostname)
        echo "📍 Nó atual: $CURRENT_NODE"
        
        read -p "Deseja criar template no nó atual? (Y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Nn]$ ]]; then
            read -p "Digite o nome do nó desejado: " CURRENT_NODE
        fi
        
        create_template_on_node "$CURRENT_NODE"
        ;;
        
    "auto")
        echo "🎯 Modo: Detecção automática"
        
        if list_cluster_nodes; then
            NODES_ARRAY=($(pvecm nodes | grep "^[[:space:]]*[0-9]" | awk '{print $3}' | grep -v "^$"))
            echo ""
            echo "🤔 Escolha uma opção:"
            echo "1) Criar template em todos os nós (${#NODES_ARRAY[@]} nós)"
            echo "2) Criar template em nó específico"
            echo "3) Cancelar"
            read -p "Opção (1-3): " -n 1 -r
            echo
            
            case $REPLY in
                1)
                    echo "🔄 Criando templates em todos os nós..."
                    validate_connectivity "${NODES_ARRAY[@]}" || exit 1
                    
                    success_count=0
                    for node in "${NODES_ARRAY[@]}"; do
                        if create_template_on_node "$node"; then
                            ((success_count++))
                        fi
                        echo ""
                    done
                    
                    echo "🎉 Resumo: $success_count/${#NODES_ARRAY[@]} templates criados com sucesso!"
                    ;;
                2)
                    echo "📋 Nós disponíveis:"
                    echo "${NODES_ARRAY[@]}" | tr ' ' '\n' | nl -w2 -s'. '
                    read -p "Digite o nome do nó: " SELECTED_NODE
                    create_template_on_node "$SELECTED_NODE"
                    ;;
                3)
                    echo "❌ Operação cancelada"
                    exit 0
                    ;;
                *)
                    echo "❌ Opção inválida"
                    exit 1
                    ;;
            esac
        else
            echo "💡 Execute em modo 'single' ou forneça os nós manualmente"
            echo "Uso: $0 single"
            echo "     $0 node1,node2,node3"
            exit 1
        fi
        ;;
        
    *)
        echo "🎯 Modo: Nós específicos"
        IFS=',' read -ra NODES_ARRAY <<< "$1"
        echo "📋 Nós especificados: ${NODES_ARRAY[*]}"
        
        validate_connectivity "${NODES_ARRAY[@]}" || exit 1
        
        success_count=0
        for node in "${NODES_ARRAY[@]}"; do
            if create_template_on_node "$node"; then
                ((success_count++))
            fi
            echo ""
        done
        
        echo "🎉 Resumo: $success_count/${#NODES_ARRAY[@]} templates criados com sucesso!"
        ;;
esac

echo ""
echo "📋 Próximos passos:"
echo "1. Configure terraform.tfvars com o nó onde está o template"
echo "2. Execute: terraform init && terraform apply"
echo "3. Aguarde a criação do cluster Kubernetes"
echo ""
echo "🔍 Para verificar templates criados:"
echo "   pvesh get /cluster/resources --type vm | grep template"
echo ""
echo "✨ Template Ubuntu 24.04 pronto para uso!"
