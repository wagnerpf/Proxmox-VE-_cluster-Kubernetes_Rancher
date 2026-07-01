#!/bin/bash

# Script de setup inicial para o projeto Terraform + Ansible + Proxmox + Kubernetes

set -e

echo "=== Setup do Projeto Terraform + Ansible + Proxmox + Kubernetes ==="

# Verificar dependências
echo "Verificando dependências..."

# Terraform
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform não encontrado. Instale: https://developer.hashicorp.com/terraform/downloads"
    exit 1
else
    echo "✅ Terraform encontrado: $(terraform version | head -n1)"
fi

# Ansible
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible não encontrado. Instale: pip3 install ansible"
    exit 1
else
    echo "✅ Ansible encontrado: $(ansible --version | head -n1)"
fi

# Python3
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 não encontrado."
    exit 1
else
    echo "✅ Python3 encontrado: $(python3 --version)"
fi

# jq
if ! command -v jq &> /dev/null; then
    echo "⚠️  jq não encontrado. Instalando..."
    sudo apt-get update && sudo apt-get install -y jq
fi

echo ""
echo "=== Configurando Ansible ==="

# Instalar coleções do Ansible
echo "Instalando coleções do Ansible..."
ansible-galaxy collection install -r ansible/requirements.yml

# Instalar dependências Python
echo "Instalando dependências Python..."
pip3 install kubernetes

echo ""
echo "=== Verificando configuração ==="

# Verificar se terraform.tfvars existe
if [ ! -f terraform.tfvars ]; then
    echo "⚠️  Arquivo terraform.tfvars não encontrado."
    echo "Copiando terraform.tfvars.example para terraform.tfvars..."
    cp terraform.tfvars.example terraform.tfvars
    echo "📝 IMPORTANTE: Edite o arquivo terraform.tfvars com suas configurações!"
    echo "   - URL e credenciais do Proxmox"
    echo "   - Configurações de rede"
    echo "   - Chave SSH pública"
fi

# Verificar chave SSH
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "⚠️  Chave SSH não encontrada em ~/.ssh/id_rsa"
    echo "Gerando nova chave SSH..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "✅ Chave SSH gerada."
fi

echo ""
echo "=== Setup concluído! ==="
echo ""
echo "Próximos passos:"
echo "1. Edite o arquivo terraform.tfvars com suas configurações"
echo "2. Execute: make init"
echo "3. Execute: make plan"
echo "4. Execute: make apply"
echo "5. Aguarde a configuração completar"
echo ""
echo "Comandos úteis:"
echo "  make help          - Ver todos os comandos disponíveis"
echo "  make check         - Verificar status do cluster"
echo "  make ssh-master    - Conectar no master via SSH"
echo "  make get-kubeconfig - Baixar arquivo kubeconfig"
echo ""
echo "📋 Checklist antes de continuar:"
echo "  [ ] Proxmox VE funcionando e acessível"
echo "  [ ] Template ubuntu-22.04-cloud criado no Proxmox"
echo "  [ ] Token de API do Proxmox criado"
echo "  [ ] Arquivo terraform.tfvars configurado"
echo "  [ ] Rede e IPs disponíveis conforme configuração"
echo ""
