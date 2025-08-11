.PHONY: help init plan apply destroy check deploy clean ansible-setup ansible-run

# Variáveis
TERRAFORM := terraform
KUBECTL := kubectl
ANSIBLE := ansible-playbook
KUBECONFIG_FILE := ./kubeconfig

# Help
help:
	@echo "🚀 Comandos disponíveis:"
	@echo ""
	@echo "📋 PREPARAÇÃO:"
	@echo "  prerequisites     - Instalar pré-requisitos necessários"
	@echo "  show-ips          - Mostrar IPs que serão atribuídos"
	@echo "  check-ips         - Verificar se IPs estão livres"
	@echo ""
	@echo "🏗️  INFRAESTRUTURA:"
	@echo "  init              - Inicializar Terraform"
	@echo "  plan              - Planejar execução do Terraform"
	@echo "  apply             - Aplicar configuração do Terraform"
	@echo "  install           - Instalação completa (Terraform + Ansible)"
	@echo "  destroy           - Destruir infraestrutura"
	@echo ""
	@echo "⚙️  CONFIGURAÇÃO:"
	@echo "  ansible-setup     - Instalar dependências do Ansible"
	@echo "  ansible-run       - Executar playbooks Ansible manualmente"
	@echo "  ping              - Testar conectividade SSH"
	@echo ""
	@echo "🔍 VERIFICAÇÃO:"
	@echo "  check             - Verificar status do cluster"
	@echo "  validate          - Validação completa do cluster"
	@echo "  status            - Status detalhado da infraestrutura"
	@echo ""
	@echo "🌐 ACESSO:"
	@echo "  rancher-info      - Mostrar informações do Rancher"
	@echo "  ssh-master        - Conectar via SSH no master"
	@echo "  urls              - Mostrar todas as URLs de acesso"
	@echo ""
	@echo "🧹 UTILITÁRIOS:"
	@echo "  clean             - Limpar arquivos temporários"
	@echo "  logs              - Mostrar logs do cluster"
	@echo "  debug             - Informações de debug"

# Instalar pré-requisitos
prerequisites:
	@echo "📦 Instalando pré-requisitos..."
	@chmod +x scripts/install-prerequisites.sh
	@./scripts/install-prerequisites.sh

# Instalação completa
install: prerequisites init
	@echo "🚀 Iniciando instalação completa..."
	@echo "1/3 - Aplicando Terraform..."
	@$(TERRAFORM) apply -auto-approve
	@echo "⏳ Aguardando VMs inicializarem completamente..."
	@sleep 60
	@echo "2/3 - Executando Ansible..."
	@cd ansible && $(ANSIBLE) -i inventory site.yml
	@echo "3/3 - Validando cluster..."
	@$(MAKE) validate
	@echo "✅ Instalação concluída com sucesso!"

# Validação completa
validate:
	@echo "🔍 Validando cluster..."
	@chmod +x scripts/validate-cluster.sh
	@./scripts/validate-cluster.sh

# Verificar se IPs estão livres  
check-ips:
	@echo "🔍 Verificando se IPs estão livres na sua rede..."
	@echo ""
	@echo "💡 Configure os IPs em terraform.tfvars conforme sua rede"
	@echo "📋 Exemplo de verificação:"
	@echo "   ping -c 1 SEU_MASTER_IP"
	@echo "   ping -c 1 SEU_WORKER_IP_1"
	@echo "   ping -c 1 SEU_WORKER_IP_2"
	@echo ""
	@echo "💡 Se algum IP estiver em uso, edite terraform.tfvars para usar IPs diferentes"

# URLs de acesso
urls:
	@echo "🌐 URLs de Acesso do Cluster:"
	@echo ""
	@echo "📊 Kubernetes API:"
	@echo "   https://SEU_MASTER_IP:6443"
	@echo ""
	@echo "🎛️  Rancher UI (após instalação):"
	@echo "   https://SEU_MASTER_IP"
	@echo "   https://SEU_MASTER_IP:8443"
	@echo ""
	@echo "🔐 Para acessar o Rancher:"
	@echo "   Usuário: admin"
	@echo "   Senha: Use 'make rancher-info' para ver a senha inicial"

# IP verification
show-ips:
	@echo "🔍 Verificando IPs que serão atribuídos..."
	@if [ -f terraform.tfvars ]; then \
		$(TERRAFORM) output -json ip_assignment_summary 2>/dev/null || \
		$(TERRAFORM) plan -var-file=terraform.tfvars 2>/dev/null | grep -E "(master|worker).*ip=" || \
		echo "Execute 'make plan' para ver os IPs que serão atribuídos"; \
	else \
		echo "❌ Arquivo terraform.tfvars não encontrado"; \
		echo "💡 Configure primeiro: cp terraform.tfvars.example terraform.tfvars"; \
	fi

# Template creation
create-template:
	@echo "Criando template Ubuntu 22.04..."
	@chmod +x scripts/create-template.sh
	@./scripts/create-template.sh

# Terraform commands
init:
	@echo "Inicializando Terraform..."
	$(TERRAFORM) init

plan:
	@echo "Planejando execução..."
	$(TERRAFORM) plan

apply:
	@echo "Aplicando configuração..."
	$(TERRAFORM) apply

# Status detalhado
status:
	@echo "📊 Status da Infraestrutura Kubernetes"
	@echo "=========================================="
	@echo ""
	@echo "🏗️  TERRAFORM:"
	@if [ -f .terraform/terraform.tfstate ]; then \
		echo "✅ Terraform inicializado"; \
	else \
		echo "❌ Terraform não inicializado - execute 'make init'"; \
	fi
	@if [ -f terraform.tfstate ] && [ -s terraform.tfstate ]; then \
		echo "✅ Infraestrutura provisionada"; \
		$(TERRAFORM) output -json 2>/dev/null | jq -r '.master_ips.value[]? // empty' | while read ip; do \
			echo "   📍 Master: $$ip"; \
		done; \
		$(TERRAFORM) output -json 2>/dev/null | jq -r '.worker_ips.value[]? // empty' | while read ip; do \
			echo "   📍 Worker: $$ip"; \
		done; \
	else \
		echo "❌ Infraestrutura não provisionada - execute 'make apply'"; \
	fi
	@echo ""
	@echo "⚙️  KUBERNETES:"
	@if [ -f $(KUBECONFIG_FILE) ]; then \
		echo "✅ Kubeconfig disponível"; \
		KUBECONFIG=$(KUBECONFIG_FILE) $(KUBECTL) cluster-info 2>/dev/null | head -1 || echo "❌ Cluster não acessível"; \
		KUBECONFIG=$(KUBECONFIG_FILE) $(KUBECTL) get nodes 2>/dev/null | grep -c Ready | xargs echo "   📊 Nodes prontos:" || echo "❌ Nodes não acessíveis"; \
	else \
		echo "❌ Kubeconfig não encontrado"; \
	fi
	@echo ""
	@echo "🌐 RANCHER:"
	@if [ -f $(KUBECONFIG_FILE) ]; then \
		KUBECONFIG=$(KUBECONFIG_FILE) $(KUBECTL) get pods -n cattle-system 2>/dev/null | grep -c Running | xargs echo "   📊 Pods rodando:" || echo "❌ Rancher não instalado"; \
	fi
	@echo ""

destroy:
	@echo "Destruindo infraestrutura..."
	$(TERRAFORM) destroy

# Ansible commands
ansible-setup:
	@echo "Instalando dependências do Ansible..."
	@ansible-galaxy collection install -r ansible/requirements.yml
	@pip3 install kubernetes

ansible-run:
	@echo "Executando playbooks Ansible..."
	@cd ansible && $(ANSIBLE) -i inventory site.yml

# Kubernetes commands
check:
	@echo "Verificando cluster..."
	@chmod +x scripts/check-cluster.sh
	@./scripts/check-cluster.sh

# Utilities
rancher-info:
	@echo "🌐 Informações do Rancher:"
	@echo ""
	@echo "📊 URLs de Acesso:"
	@echo "   https://SEU_MASTER_IP"
	@echo "   https://SEU_MASTER_IP:8443"
	@echo ""
	@echo "🔐 Credenciais:"
	@echo "   Usuário: admin"
	@echo "   Senha: admin123 (padrão)"
	@echo ""
	@echo "💡 Para obter a senha real do bootstrap:"
	@echo "   ssh -i ~/.ssh/k8s-cluster-key -o StrictHostKeyChecking=no SEU_USUARIO@SEU_MASTER_IP \"sudo docker logs rancher-server 2>&1 | grep 'Bootstrap Password:' | tail -1\""

ssh-master:
	@echo "Conectando no master via SSH..."
	@echo "(Configure o IP e usuário corretos em terraform.tfvars)"
	@echo "Exemplo de comando:"
	@echo "ssh -i ~/.ssh/k8s-cluster-key -o StrictHostKeyChecking=no SEU_USUARIO@SEU_MASTER_IP"

get-kubeconfig:
	@echo "Baixando kubeconfig do master..."
	@echo "(Configure o IP e usuário corretos)"
	@echo "Exemplo de comando:"
	@echo "scp -i ~/.ssh/k8s-cluster-key -o StrictHostKeyChecking=no SEU_USUARIO@SEU_MASTER_IP:/home/SEU_USUARIO/.kube/config $(KUBECONFIG_FILE)"

deploy:
	@echo "Fazendo deploy de aplicação exemplo..."
	@chmod +x scripts/deploy-example.sh
	@./scripts/deploy-example.sh

# Verificar se terraform.tfvars existe
check-config:
	@if [ ! -f terraform.tfvars ]; then \
		echo "Arquivo terraform.tfvars não encontrado!"; \
		echo "Copie terraform.tfvars.example para terraform.tfvars e configure suas variáveis."; \
		exit 1; \
	fi

# Teste de conectividade
ping:
	@echo "🔗 Testando conectividade SSH..."
	@cd ansible && ansible all -i inventory -m ping

# Logs do cluster
logs:
	@echo "📋 Coletando logs do cluster..."
	@mkdir -p logs
	@cd ansible && ansible masters -i inventory -m shell -a "kubectl logs -n cattle-system deployment/rancher --tail=50" > ../logs/rancher.log 2>/dev/null || true
	@cd ansible && ansible masters -i inventory -m shell -a "kubectl get events --all-namespaces --sort-by='.lastTimestamp'" > ../logs/events.log 2>/dev/null || true
	@echo "✅ Logs salvos em logs/"

# Debug information
debug:
	@echo "🐛 Informações de debug:"
	@echo "Terraform version: $$($(TERRAFORM) version | head -1)"
	@echo "Ansible version: $$(ansible --version | head -1)"
	@echo "Python version: $$(python3 --version)"
	@echo "Kubectl version: $$(kubectl version --client --short 2>/dev/null || echo 'não instalado')"
	@echo "Helm version: $$(helm version --short 2>/dev/null || echo 'não instalado')"

clean:
	@echo "🧹 Limpando arquivos temporários..."
	@rm -f ansible/inventory
	@rm -f $(KUBECONFIG_FILE)
	@rm -f .terraform.lock.hcl
	@rm -rf logs/*
	@echo "✅ Limpeza concluída"
