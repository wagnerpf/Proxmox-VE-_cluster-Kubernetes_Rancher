# 🚀 Terraform Proxmox Kubernetes Cluster com Rancher

Este projeto provisiona um cluster Kubernetes no Proxmox VE usando Terraform e configura o cluster com Ansible, incluindo instalação do Rancher para gerenciamento.

## ✨ Características

- **🎯 IPs Fixos**: Configuração com IPs fixos para maior controle e previsibilidade
- **🚀 Ubuntu 22.04 LTS**: Versão estável e confiável com suporte estendido
- **⚡ Kubernetes 1.28.2**: Versão estável e atual do Kubernetes
- **🌐 Rancher 2.7.5**: Interface web completa para gerenciamento do cluster
- **🔧 Automação completa**: Do provisionamento à configuração, tudo automatizado
- **📊 Cluster Proxmox**: Suporte completo para clusters Proxmox VE
- **🔐 SSH Key Authentication**: Autenticação segura por chave SSH
- **🏷️ Tags Padronizadas**: Organização com tags consistentes
- **✅ Validações Robustas**: Prevenção de configurações inválidas
- **📋 Melhores Práticas**: Implementação seguindo padrões de segurança

## 📋 Configuração Padrão (Rede Genérica)

| Componente | IP Fixo | Recursos |
|------------|---------|----------|
| **Master** | 192.168.1.10 | 4 vCPU, 8GB RAM, 80GB |
| **Worker 1** | 192.168.1.20 | 4 vCPU, 16GB RAM, 50GB |
| **Worker 2** | 192.168.1.21 | 4 vCPU, 16GB RAM, 50GB |

### 🌐 Acessos do Cluster
- **Kubernetes API**: `https://192.168.1.10:6443`
- **Rancher UI**: `https://192.168.1.10:8443`
  - **Usuário**: admin
  - **Senha**: admin123
- **SSH Access**: `ssh -i ~/.ssh/k8s-cluster-key ubuntu@IP_DO_NO`

## 📋 Pré-requisitos

### 1. 🖥️ Proxmox VE
- Proxmox VE 7.0+ instalado e configurado
- Template Ubuntu 22.04 Cloud-Init criado
- Token de API configurado com permissões adequadas
- Recursos suficientes (mínimo: 8 vCPU, 40GB RAM, 180GB storage)

### 2. 🛠️ Ferramentas Locais
- **Terraform** >= 1.0
- **Ansible** >= 2.12
- **Python** 3.8+
- **Git** para versionamento
- **SSH Client** configurado

### 3. 🔐 Autenticação SSH
Gere um par de chaves SSH dedicado para o cluster:

```bash
# Gerar chave SSH para o cluster
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key -C "k8s-cluster@$(hostname)"

# Verificar se as chaves foram criadas
ls -la ~/.ssh/k8s-cluster-key*
```

**Importante**: O projeto está configurado para usar `~/.ssh/k8s-cluster-key` por padrão.
### 4. 📦 Template Ubuntu 22.04
**Para cluster Proxmox:** O template pode ser criado em qualquer nó, mas as VMs serão criadas no mesmo nó do template.

#### **Opção A: Script Automatizado (Recomendado)**
```bash
# Executar script no nó Proxmox ou com SSH configurado
./scripts/create-template.sh

# Opções disponíveis:
# ./scripts/create-template.sh single          # Um nó apenas
# ./scripts/create-template.sh auto            # Detecção automática
# ./scripts/create-template.sh node1,node2     # Nós específicos
```

#### **Opção B: Manual**
Crie um template Ubuntu 22.04 com cloud-init no Proxmox:

```bash
# No Proxmox, criar template (executar no shell do Proxmox)
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-22.04-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --scsi1 local-lvm:cloudinit
qm set 9000 --vga qxl
qm set 9000 --agent enabled=1
qm template 9000
```

**⚠️ Importante:** Anote o **nome do nó** onde criou o template para configurar no `terraform.tfvars`.

### 5. 🔑 Token de API do Proxmox
Criar um token de API no Proxmox:

1. Acesse a interface web do Proxmox
2. Vá em Datacenter > Permissions > API Tokens
3. Crie um novo token para o usuário root@pam
4. Marque "Privilege Separation" como false

### 4. Chaves SSH
Gere um par de chaves SSH se ainda não tiver:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### 5. Instalar dependências do Ansible
```bash
# Instalar coleções necessárias
ansible-galaxy collection install -r ansible/requirements.yml

# Instalar dependências Python
pip3 install kubernetes
```

## ⚙️ Configuração

### 1. 📥 Clonar e Configurar o Projeto

```bash
git clone <este-repositorio>
cd terraform-proxmox-k8s
chmod +x scripts/*.sh
```

### 2. � Instalação Rápida (Recomendada)

```bash
# Instalar pré-requisitos e inicializar
make prerequisites
make init

# Configurar variáveis (editar conforme sua infraestrutura)
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars

# Executar instalação completa
make install
```

### 3. 🎯 Configuração Manual

#### **3.1. Configurar Variáveis do Terraform**
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edite o arquivo `terraform.tfvars` com suas configurações:

```hcl
# ========================================
# CONFIGURAÇÕES DO PROXMOX VE - OBRIGATÓRIO
# ========================================
proxmox_api_url          = "https://your-proxmox-server.domain.com:8006/api2/json"
proxmox_api_token_id     = "your-user@pve!your-token-name"
proxmox_api_token_secret = "your-token-secret-here"
proxmox_node             = "your-proxmox-node"

# ========================================
# CONFIGURAÇÕES DO AMBIENTE
# ========================================
environment = "production"  # development, staging, production

# ========================================
# CONFIGURAÇÕES DO CLUSTER
# ========================================
cluster_name = "my-k8s-cluster"
master_count = 1
worker_count = 2
template_name = "ubuntu-22.04-cloud"

# ========================================
# CONFIGURAÇÕES DE REDE
# ========================================
network_bridge  = "vmbr0"
network_gateway = "192.168.1.1"
dns_servers     = "8.8.8.8,8.8.4.4"
search_domain   = "local"

# IPs fixos para os nós
master_ips = ["192.168.1.10"]
worker_ips = ["192.168.1.20", "192.168.1.21"]

# ========================================
# CONFIGURAÇÕES DE SEGURANÇA
# ========================================
ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
vm_user             = "ubuntu"
vm_password         = "your-secure-password"  # Usado apenas como fallback

# ========================================
# CONFIGURAÇÕES DE HARDWARE
# ========================================
# Masters
master_memory    = 8192   # 8GB RAM
master_cpu       = 4      # 4 vCPUs
master_disk_size = "80G"

# Workers
worker_memory    = 16384  # 16GB RAM
worker_cpu       = 4      # 4 vCPUs
worker_disk_size = "50G"
```

**🔐 Segurança**: Use variáveis de ambiente para tokens em produção:
```bash
export TF_VAR_proxmox_api_token_secret="seu-token-aqui"
```

## 🚀 Execução

### 🎯 Método Recomendado (Make)

```bash
# 1. Instalar dependências
make prerequisites

# 2. Inicializar Terraform
make init

# 3. Planejar execução
make plan

# 4. Aplicar configuração completa
make install
```

### 🔧 Método Manual (Terraform + Ansible)

#### **1. Inicializar Terraform**
```bash
terraform init
```

#### **2. Planejar a Execução**
```bash
terraform plan
```

#### **3. Aplicar a Configuração**
```bash
terraform apply
```

#### **4. Aguardar e Configurar Cluster**
O processo irá:
1. ✅ Criar as VMs no Proxmox com SSH keys
2. ✅ Gerar inventário do Ansible automaticamente
3. ✅ Aguardar VMs inicializarem (60 segundos)
4. ✅ Executar playbooks Ansible:
   - Preparar sistemas operacionais
   - Instalar Docker em todos os nós
   - Instalar Kubernetes (kubeadm, kubelet, kubectl)
   - Configurar o master node com Flannel CNI
   - Adicionar workers ao cluster
   - Instalar cert-manager
   - Instalar e configurar Rancher

**⏱️ Tempo Estimado**: 15-20 minutos (dependendo da velocidade da internet e recursos)

## Pós-instalação

### 1. Verificar o cluster
```bash
# Usar Makefile
make check

# Ou manualmente
cd ansible && ansible-playbook -i inventory check-cluster.yml
```

### 2. Acessar o Rancher
Após a instalação, o Rancher estará disponível em:
- URL: https://rancher.local (configurar no /etc/hosts)
- IP direto: https://<MASTER_IP>
- Usuário: admin
- Senha inicial: admin123

Para configurar o acesso:
```bash
# Adicionar ao /etc/hosts
echo "<MASTER_IP> rancher.local" | sudo tee -a /etc/hosts
```

### 3. Obter kubeconfig
### 3. Obter kubeconfig
Após a aplicação, copie o arquivo kubeconfig do master:

```bash
# Usar Makefile
make get-kubeconfig

# Ou manualmente
scp -i ~/.ssh/id_rsa ubuntu@<MASTER_IP>:~/.kube/config ./kubeconfig
```

### 4. Verificar o cluster

```bash
# Usar o kubeconfig baixado
kubectl --kubeconfig=./kubeconfig get nodes
kubectl --kubeconfig=./kubeconfig get pods -A
```

### 5. Conectar nas VMs

```bash
# Usar Makefile
make ssh-master

# Ou manualmente
ssh -i ~/.ssh/id_rsa ubuntu@<MASTER_IP>
ssh -i ~/.ssh/id_rsa ubuntu@<WORKER_IP>
```

## Estrutura do projeto

```
├── main.tf                      # Configuração principal do Terraform
├── variables.tf                 # Definição de variáveis
├── outputs.tf                   # Outputs do Terraform
├── terraform.tfvars.example     # Exemplo de configuração
├── Makefile                     # Comandos automatizados
├── README.md                    # Este arquivo
├── ansible/                     # Configuração Ansible
│   ├── site.yml                 # Playbook principal
│   ├── inventory.tpl            # Template do inventário
│   ├── ansible.cfg              # Configuração Ansible
│   ├── requirements.yml         # Dependências Ansible
│   ├── group_vars/
│   │   └── all.yml              # Variáveis globais
│   └── roles/                   # Roles Ansible
│       ├── common/              # Preparação básica
│       ├── docker/              # Instalação Docker
│       ├── kubernetes/          # Instalação Kubernetes
│       ├── kubernetes-master/   # Configuração master
│       ├── kubernetes-worker/   # Configuração workers
│       └── rancher/             # Instalação Rancher
└── scripts/                     # Scripts auxiliares
    ├── check-cluster.sh         # Verificar cluster
    └── deploy-example.sh        # Deploy de exemplo
```

## 🛠️ Comandos Úteis (Makefile)

```bash
# ===== INSTALAÇÃO =====
make prerequisites      # Instalar dependências
make init              # Inicializar Terraform
make plan              # Planejar mudanças
make install           # Instalação completa
make apply             # Aplicar apenas Terraform

# ===== VERIFICAÇÃO =====
make check             # Verificar cluster
make validate          # Validar configuração
make get-kubeconfig    # Baixar kubeconfig

# ===== ACESSO SSH =====
make ssh-master        # Conectar no master
make ssh-worker-1      # Conectar no worker 1
make ssh-worker-2      # Conectar no worker 2

# ===== MANUTENÇÃO =====
make clean-ssh-keys    # Limpar chaves SSH conhecidas
make logs              # Ver logs do deployment
make status            # Status dos recursos

# ===== DESTRUIÇÃO =====
make destroy           # Destruir infraestrutura
make clean             # Limpar arquivos temporários
```

### 📊 Comandos de Monitoramento

```bash
# Status dos nós
kubectl --kubeconfig=./ansible/kubeconfig get nodes -o wide

# Pods do sistema
kubectl --kubeconfig=./ansible/kubeconfig get pods -A

# Status do Rancher
kubectl --kubeconfig=./ansible/kubeconfig get pods -n cattle-system

# Recursos do cluster
kubectl --kubeconfig=./ansible/kubeconfig top nodes
```

## Personalização

### Alterar recursos das VMs
Edite as variáveis no `terraform.tfvars`:

```hcl
# Master nodes
master_memory    = 4096  # MB
master_cpu       = 2
master_disk_size = "50G"

# Worker nodes
worker_memory    = 8192  # MB
worker_cpu       = 4
worker_disk_size = "100G"
```

### Adicionar mais workers
Altere a variável `worker_count`:

```hcl
worker_count = 3  # Para 3 workers
```

### Configurar rede diferente
Ajuste as configurações de rede:

```hcl
network_cidr    = "10.0.0.0/24"
network_gateway = "10.0.0.1"
```

## Troubleshooting

### VMs não inicializam
- Verifique se o template existe no Proxmox
- Confirme se o nome do nó está correto
- Verifique se há recursos suficientes

### Erro de SSH
- Confirme se a chave SSH está correta
- Verifique se as VMs têm acesso à internet
- Confirme se o cloud-init está funcionando

### Cluster não forma
- Verifique logs: `journalctl -u kubelet`
- Confirme conectividade entre nós
- Verifique se as portas necessárias estão abertas

### Comandos úteis

```bash
# Ver status das VMs no Proxmox
pvesh get /cluster/resources --type vm

# Logs do cloud-init nas VMs
sudo cat /var/log/cloud-init-output.log

# Status do kubelet
sudo systemctl status kubelet

# Logs do kubelet
sudo journalctl -u kubelet -f
```

## Limpeza

Para destruir toda a infraestrutura:

```bash
terraform destroy
```

## Componentes instalados

- **Docker**: Container runtime
- **Kubernetes 1.28**: Orquestrador de containers
- **Flannel**: Plugin de rede para pods
- **containerd**: Container runtime interface
- **cert-manager**: Gerenciamento de certificados
- **Rancher**: Plataforma de gerenciamento Kubernetes

## Rancher - Funcionalidades

O Rancher fornece:
- Interface web para gerenciar clusters Kubernetes
- Gestão de usuários e permissões
- Monitoramento e alertas
- Catálogo de aplicações
- Backup e restore
- Gestão de projetos e namespaces

## Troubleshooting

### VMs não inicializam
- Verifique se o template existe no Proxmox
- Confirme se o nome do nó está correto
- Verifique se há recursos suficientes

### Erro de SSH/Ansible
- Confirme se a chave SSH está correta
- Verifique se as VMs têm acesso à internet
- Confirme se o cloud-init está funcionando
- Teste conectividade: `ansible all -m ping`

### Cluster não forma
- Verifique logs: `journalctl -u kubelet`
- Confirme conectividade entre nós
- Verifique se as portas necessárias estão abertas

### Rancher não acessa
- Verifique se todos os pods estão rodando: `kubectl get pods -n cattle-system`
- Confirme se cert-manager está funcionando: `kubectl get pods -n cert-manager`
- Verifique logs do Rancher: `kubectl logs -n cattle-system -l app=rancher`

### Comandos úteis

```bash
# Verificar status geral
kubectl get nodes
kubectl get pods -A

# Logs específicos
kubectl logs -n kube-system -l app=flannel
kubectl logs -n cattle-system -l app=rancher

# Reiniciar Rancher
kubectl rollout restart deployment/rancher -n cattle-system

# Ver status das VMs no Proxmox
pvesh get /cluster/resources --type vm

# Logs do cloud-init nas VMs
sudo cat /var/log/cloud-init-output.log

# Status do kubelet
sudo systemctl status kubelet

# Executar playbook específico
cd ansible && ansible-playbook -i inventory roles/rancher/tasks/main.yml
```
