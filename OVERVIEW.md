# 🚀 Projeto Terraform + Ansible + Proxmox + Kubernetes + Rancher

## 📋 Resumo do Projeto

Est### 🏷️ Tags Aplicadas
```
environment=production
project=my-k8s-cluster  
managed-by=terraform
kubernetes + master/worker
node-type=control-plane/worker
```o provisiona automaticamente um cluster Kubernetes completo no Proxmox VE com Rancher para gerenciamento, usando a combinação de Terraform para infraestrutura e Ansible para configuração, seguindo as melhores práticas de segurança e organização.

## � Versão Atual: **v2.0** - Enterprise Ready

### ✨ **Novidades v2.0**
- 🔐 **SSH Key Authentication** exclusivo
- 🏷️ **Tags padronizadas** para gestão
- ✅ **Validações robustas** de configuração
- 📊 **Outputs informativos** e seguros
- 🛡️ **Práticas de segurança** aprimoradas

## �🏗️ Arquitetura

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Terraform     │────│   Proxmox VE     │────│  Ubuntu 22.04   │
│  (Infraestrutura)│    │  (Virtualização) │    │     LTS VMs     │
│  + Validações   │    │ + SSH Keys Auth  │    │ + Cloud-init    │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         │                                               │
         │              ┌──────────────────┐            │
         └──────────────│     Ansible      │────────────┘
                        │  (Configuração)  │
                        │ + SSH Key Auth   │
                        └──────────────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
        ┌───────▼────────┐ ┌─────▼─────┐ ┌──────▼──────┐
        │    Docker      │ │Kubernetes │ │   Rancher   │
        │ (Container RT) │ │   v1.28.2 │ │   v2.7.5+   │
        │   + containerd │ │ + Flannel │ │ + cert-mgr  │
        └────────────────┘ └───────────┘ └─────────────┘
```

## 🎯 Componentes Instalados

### 🖥️ Infraestrutura (Terraform)
- **Ubuntu 22.04 LTS** no Proxmox VE
- **SSH Key Authentication** dedicado
- **IPs fixos** configuráveis
- **Tags padronizadas** para organização
- **Validações** de entrada robustas

### 🐳 Container Runtime (Ansible)
- **Docker** 24.0.5+
- **containerd** com configuração SystemdCgroup
- **Instalação** automatizada e otimizada

### ☸️ Kubernetes (Ansible)
- **kubeadm, kubelet, kubectl** v1.28.2
- **Flannel CNI** para rede de pods
- **Cluster multi-node** (1 master + N workers)
- **Configuração** HA-ready

### 🤠 Rancher (Ansible)
- **Rancher Server** v2.7.5+
- **cert-manager** para certificados TLS
- **Interface web** para gerenciamento
- **Acesso**: https://SEU_MASTER_IP:8443

## 🚀 Quick Start

```bash
# 1. Setup de SSH
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key

# 2. Configurar terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars  # Ajustar para sua infraestrutura

# 3. Instalação completa
make prerequisites  # Dependências
make install       # Provisionamento completo

# 4. Verificar cluster
make check

# 5. Acessar Rancher
echo "https://SEU_MASTER_IP:8443"
echo "User: admin / Pass: admin123"
```

## 📊 Configuração Padrão (Rede Genérica)

| Componente | IP Fixo | Recursos |
|------------|---------|----------|
| **Master** | 192.168.1.10 | 4 vCPU, 8GB RAM, 80GB |
| **Worker 1** | 192.168.1.20 | 4 vCPU, 16GB RAM, 50GB |
| **Worker 2** | 192.168.1.21 | 4 vCPU, 16GB RAM, 50GB |

### �️ Tags Aplicadas
```
environment=production
project=k8s-cluster-viana  
managed-by=terraform
kubernetes + master/worker
node-type=control-plane/worker
```

## 🔐 Segurança

### 🔑 Autenticação
- **SSH Keys** exclusivo (não usa senhas)
- **Path configurável**: `~/.ssh/k8s-cluster-key`
- **Token API** Proxmox como variável sensível

### ✅ Validações
- **Environment**: development/staging/production
- **Recursos**: Mínimos garantidos
- **Counts**: Limites de nós (1-5 masters, 0-10 workers)
- **Paths**: Validação de extensões

## 📁 Estrutura Completa

```
terraform-proxmox-k8s/
├── 🏗️  Terraform (Infraestrutura)
│   ├── main.tf                 # Recursos + locals + tags
│   ├── variables.tf            # Variáveis + validações
│   ├── outputs.tf              # Outputs seguros
│   └── terraform.tfvars.example # Configuração exemplo
│
├── 🤖 Ansible (Configuração)
│   ├── site.yml                # Playbook principal
│   ├── inventory.tpl           # Template inventário
│   ├── ansible.cfg             # SSH key auth
│   ├── requirements.yml        # Dependências
│   ├── group_vars/all.yml      # Variáveis globais
│   └── roles/                  # Roles de configuração
│       ├── common/             # Setup básico
│       ├── docker/             # Docker + containerd
│       ├── kubernetes/         # K8s base
│       ├── kubernetes-master/  # Master config
│       ├── kubernetes-worker/  # Worker config
│       └── rancher/            # Rancher install
│
├── � Scripts Auxiliares
│   ├── setup.sh               # Setup inicial
│   ├── check-cluster.sh       # Verificação
│   ├── validate-cluster.sh    # Validação SSH key
│   └── create-template.sh     # Template automation
│
├── 🛠️  Automação
│   ├── Makefile               # Comandos + delay otimizado
│   └── .gitignore             # Arquivos ignorados
│
└── 📚 Documentação
    ├── README.md              # Documentação principal
    ├── BEST-PRACTICES.md      # Melhores práticas
    ├── CHANGELOG.md           # Registro de mudanças
    ├── CLUSTER-QUICK-GUIDE.md # Guia rápido
    └── OVERVIEW.md            # Este arquivo
```

## ⚡ Comandos Principais

```bash
# === INSTALAÇÃO ===
make prerequisites     # Instalar dependências
make init             # Inicializar Terraform
make install          # Instalação completa (com delay)
make plan             # Planejar mudanças

# === VERIFICAÇÃO ===
make check            # Status do cluster
make validate         # Validar configuração
make status           # Status dos recursos

# === ACESSO ===
make ssh-master       # SSH no master
make ssh-worker-1     # SSH no worker 1
make get-kubeconfig   # Baixar kubeconfig

# === MANUTENÇÃO ===
make clean-ssh-keys   # Limpar known_hosts
make destroy          # Destruir infraestrutura
make clean            # Limpar temporários
```

## 🎯 Casos de Uso

### 🧪 **Desenvolvimento**
- Ambiente K8s local completo
- Testes de aplicações containerizadas
- Experimentos com Rancher

### 🏫 **Laboratório/Educacional**
- Treinamento em Kubernetes
- Demos e apresentações
- Ambiente de aprendizado
- Simulação de ambientes produtivos

### 🏢 **Produção Small/Medium**
- Clusters pequenos/médios
- Proof of Concepts
- Ambientes de staging
- Infraestrutura institucional

## 🚨 Próximos Passos após Instalação

1. **✅ Verificar Status**: `make check`
2. **🌐 Acessar Rancher**: https://SEU_MASTER_IP:8443
3. **📋 Baixar kubeconfig**: `make get-kubeconfig`
4. **🚀 Deploy aplicações**: Via Rancher UI ou kubectl
5. **📊 Configurar monitoring**: Prometheus + Grafana
6. **🔐 Configurar RBAC**: Usuários e permissões
7. **💾 Estratégia backup**: Volumes e configurações

## 🆘 Troubleshooting

### 🔍 **Logs Úteis**
```bash
# Cloud-init nas VMs
sudo cat /var/log/cloud-init-output.log

# Kubelet
sudo journalctl -u kubelet -f

# Rancher
kubectl logs -n cattle-system -l app=rancher

# Ansible detalhado
cd ansible && ansible-playbook -i inventory site.yml -vvv
```

### 🚑 **Comandos de Diagnóstico**
```bash
make status           # Status geral
make logs            # Logs de deployment
kubectl get nodes -o wide
kubectl get pods -A
```

---

✨ **Enterprise Ready!** Seu cluster Kubernetes com Rancher seguro e bem organizado está pronto para produção!


## 📁 Estrutura Completa

```
terraform-proxmox-k8s/
├── 🏗️  Terraform (Infraestrutura)
│   ├── main.tf                 # Recursos principais
│   ├── variables.tf            # Variáveis
│   ├── outputs.tf              # Outputs
│   └── terraform.tfvars.example # Configuração exemplo
│
├── 🤖 Ansible (Configuração)
│   ├── site.yml                # Playbook principal
│   ├── inventory.tpl           # Template inventário
│   ├── ansible.cfg             # Configuração Ansible
│   ├── requirements.yml        # Dependências
│   ├── group_vars/all.yml      # Variáveis globais
│   └── roles/                  # Roles de configuração
│       ├── common/             # Setup básico
│       ├── docker/             # Docker + containerd
│       ├── kubernetes/         # K8s base
│       ├── kubernetes-master/  # Master config
│       ├── kubernetes-worker/  # Worker config
│       └── rancher/            # Rancher install
│
├── 📜 Scripts Auxiliares
│   ├── setup.sh               # Setup inicial
│   ├── check-cluster.sh       # Verificação
│   └── deploy-example.sh      # Deploy exemplo
│
├── 🛠️  Automação
│   ├── Makefile               # Comandos automatizados
│   └── .gitignore             # Arquivos ignorados
│
└── 📚 Documentação
    ├── README.md              # Documentação principal
    └── terraform.tfvars.detailed # Configuração detalhada
```

## ⚡ Comandos Rápidos

```bash
# Gerenciamento da infraestrutura
make init          # Inicializar Terraform
make plan          # Planejar mudanças
make apply         # Criar infraestrutura
make destroy       # Destruir tudo

# Gerenciamento do cluster
make check         # Verificar status
make ssh-master    # SSH no master
make get-kubeconfig # Baixar kubeconfig
make rancher-info  # Info do Rancher

# Ansible específico
make ansible-setup # Instalar dependências
make ansible-run   # Executar playbooks

# Limpeza
make clean         # Limpar temporários
```

## 🎯 Casos de Uso

### 🧪 Desenvolvimento
- Ambiente K8s local completo
- Testes de aplicações containerizadas
- Experimentos com Rancher

### 🏫 Laboratório
- Treinamento em Kubernetes
- Demos e apresentações
- Ambiente de aprendizado

### 🏢 Produção Small
- Clusters pequenos/médios
- Proof of Concepts
- Ambientes de staging

## 🚨 Próximos Passos após Instalação

1. **Configurar DNS**: Adicionar rancher.local ao /etc/hosts
2. **Explorar Rancher**: Interface web rica em funcionalidades
3. **Deploy aplicações**: Usar catálogo do Rancher ou kubectl
4. **Configurar monitoring**: Prometheus + Grafana via Rancher
5. **Backup/Restore**: Configurar estratégias de backup
6. **Segurança**: Configurar RBAC e políticas de rede

## 🆘 Suporte

- **Issues**: Logs em `/var/log/cloud-init-output.log` nas VMs
- **Kubernetes**: `kubectl logs` e `journalctl -u kubelet`
- **Rancher**: Logs em namespace `cattle-system`
- **Ansible**: Execute com `-vvv` para debug detalhado

---

✨ **Pronto para usar!** Seu cluster Kubernetes com Rancher está a apenas alguns comandos de distância!
