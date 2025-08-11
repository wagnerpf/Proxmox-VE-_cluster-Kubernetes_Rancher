#!/bin/bash

# Script para instalar pré-requisitos do projeto
# Executa antes do terraform apply

set -e

echo "🚀 Instalando pré-requisitos do projeto Kubernetes..."

# Verificar se estamos no diretório correto
if [ ! -f "main.tf" ]; then
    echo "❌ Execute este script no diretório raiz do projeto Terraform"
    exit 1
fi

# 1. Instalar collections do Ansible
echo "📦 Instalando collections do Ansible..."
cd ansible
if [ -f "requirements.yml" ]; then
    ansible-galaxy collection install -r requirements.yml --force
    echo "✅ Collections instaladas"
else
    echo "⚠️  requirements.yml não encontrado"
fi

# 2. Instalar dependências Python
echo "🐍 Instalando dependências Python..."
if command -v pip3 &> /dev/null; then
    pip3 install --user kubernetes pyyaml requests urllib3
    echo "✅ Dependências Python instaladas"
else
    echo "⚠️  pip3 não encontrado, instalando via apt..."
    sudo apt update
    sudo apt install -y python3-pip
    pip3 install --user kubernetes pyyaml requests urllib3
fi

# 3. Verificar conectividade com Proxmox
echo "🔗 Verificando conectividade com Proxmox..."
cd ..
if [ -f "terraform.tfvars" ]; then
    PROXMOX_URL=$(grep proxmox_api_url terraform.tfvars | cut -d'"' -f2)
    if curl -k -s --connect-timeout 5 "$PROXMOX_URL" > /dev/null; then
        echo "✅ Proxmox acessível"
    else
        echo "⚠️  Proxmox pode não estar acessível"
    fi
else
    echo "⚠️  terraform.tfvars não encontrado"
fi

# 4. Verificar template Ubuntu
echo "🐧 Verificando template Ubuntu..."
TEMPLATE_NAME=$(grep template_name terraform.tfvars | cut -d'"' -f2 2>/dev/null || echo "ubuntu-22.04-cloud")
echo "Template configurado: $TEMPLATE_NAME"

# 5. Criar diretório para logs
mkdir -p logs

echo ""
echo "✅ Pré-requisitos instalados com sucesso!"
echo "📋 Próximos passos:"
echo "   1. Verifique as configurações em terraform.tfvars"
echo "   2. Execute: terraform init"
echo "   3. Execute: terraform plan"
echo "   4. Execute: terraform apply"
echo ""
