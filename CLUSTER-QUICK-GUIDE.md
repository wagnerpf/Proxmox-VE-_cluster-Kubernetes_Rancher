# ⚡ Guia Rápido: Kubernetes no Proxmox VE

> **Deploy completo em 15 minutos** - Cluster Kubernetes empresarial

## 🎯 **Setup Rápido - 3 Comandos**

```bash
# 1️⃣ Preparar autenticação
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key

# 2️⃣ Configurar projeto  
cp terraform.tfvars.example terraform.tfvars && nano terraform.tfvars

# 3️⃣ Instalação completa
terraform init && terraform apply
cd ansible && ansible-playbook -i inventory site.yml && cd ..
```

**⏱️ Tempo total:** 15-20 minutos

---

## 📋 **Pré-requisitos Essenciais**

### ✅ **Checklist Básico**
- [ ] **Proxmox VE** 7.0+ funcionando
- [ ] **Template Ubuntu 22.04** criado no nó "seu-node"  
- [ ] **Token API** do Proxmox configurado
- [ ] **Terraform + Ansible** instalados na estação
- [ ] **Chaves SSH** geradas e configuradas

### 🔧 **Verificação Rápida**
```bash
# Testar ferramentas
terraform version  # >= 1.0
ansible --version  # >= 2.12
python3 --version  # >= 3.8

# Testar conectividade Proxmox
curl -k https://seu-proxmox.dominio.br:8006/api2/json/version
```

---

## ⚙️ **Configuração Essencial**

### 📝 **Arquivo terraform.tfvars (Mínimo)**

```hcl
# === PROXMOX CONNECTION ===
proxmox_api_url          = "https://seu-proxmox.dominio.br:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"  
proxmox_api_token_secret = "SEU_TOKEN_AQUI"
proxmox_node             = "seu-node"

# === CLUSTER CONFIG ===
cluster_name = "k8s-cluster-exemplo"
environment  = "production"

# === NETWORK (Instituição) ===
master_ips = ["<IP_MASTER>"]
worker_ips = ["<IP_WORKER_1>", "<IP_WORKER_2>"]

# === SSH SECURITY ===
ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
vm_user            = "<VM_USER>"
```

---

## 🚀 **Instalação Express**

### 🏃‍♂️ **Método Ultra-Rápido**
```bash
# Clone + Setup + Deploy
git clone <repo> && cd terraform-proxmox-k8s
terraform init && terraform apply
cd ansible && ansible-playbook -i inventory site.yml && cd ..
```

### 🎛️ **Método com Controle**
```bash
# 1. Preparar ambiente
chmod +x scripts/install-prerequisites.sh && ./scripts/install-prerequisites.sh

# 2. Inicializar Terraform  
terraform init

# 3. Revisar plano (opcional)
terraform plan

# 4. Aplicar infraestrutura
terraform apply

# 5. Configurar cluster via Ansible
cd ansible && ansible-playbook -i inventory site.yml && cd ..

# 6. Verificar resultado
./scripts/validate-cluster.sh
```

---

## 📊 **Resultado Esperado**

### 🖥️ **Infraestrutura Criada**
```
✅ 3 VMs Ubuntu 22.04 no Proxmox
   ├── k8s-cluster-exemplo-master-1  (<IP_MASTER>)
   ├── k8s-cluster-exemplo-worker-1  (<IP_WORKER_1>)  
   └── k8s-cluster-exemplo-worker-2  (<IP_WORKER_2>)

✅ Cluster Kubernetes v1.28.2
   ├── Control plane configurado
   ├── Workers unidos ao cluster
   └── Flannel CNI funcionando
```

### 🔗 **Pontos de Acesso**
| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Kubernetes API** | `https://<IP_MASTER>:6443` | Via kubeconfig |
| **SSH Master** | `ssh <VM_USER>@<IP_MASTER>` | Chave SSH |

---

## ✅ **Verificações Pós-Deploy**

### 🔍 **Comandos de Verificação**
```bash
# Status geral
./scripts/validate-cluster.sh

# Conectividade SSH
cd ansible && ansible all -i inventory -m ping && cd ..

# Cluster Kubernetes
kubectl --kubeconfig=./kubeconfig get nodes

# Pods do sistema
kubectl --kubeconfig=./kubeconfig get pods -A
```

### 📋 **Saída Esperada**
```bash
$ kubectl get nodes
NAME                         STATUS   ROLES           AGE   VERSION
k8s-cluster-exemplo-master-1   Ready    control-plane   5m    v1.28.2
k8s-cluster-exemplo-worker-1   Ready    <none>          4m    v1.28.2  
k8s-cluster-exemplo-worker-2   Ready    <none>          4m    v1.28.2
```

---

## 🛠️ **Comandos de Gestão**

### 📊 **Monitoramento**
```bash
terraform show                  # Status completo da infraestrutura
kubectl --kubeconfig=./kubeconfig get pods -A  # Logs/estado do deployment
./scripts/check-cluster.sh      # Verificação rápida
```

### 🔧 **Acesso e Configuração**
```bash
ssh -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_MASTER>   # SSH no master node
scp -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_MASTER>:/home/<VM_USER>/.kube/config ./kubeconfig  # Baixar kubeconfig
```

### 🧹 **Manutenção**
```bash
./scripts/clean-ssh-keys.sh   # Limpar known_hosts (VMs recriadas)
terraform destroy             # Destruir toda infraestrutura
rm -f ansible/inventory ./kubeconfig .terraform.lock.hcl  # Limpar arquivos temporários
```

---

## 🆘 **Troubleshooting Rápido**

### ❌ **Problemas Comuns**

#### **"Template não encontrado"**
```bash
# Verificar se template existe no nó correto
ssh root@seu-node "qm list | grep ubuntu-22.04-cloud"

# Se não existe, criar:
./scripts/create-template.sh
```

#### **"VMs não inicializam"**  
```bash
# Verificar recursos no Proxmox
pvesh get /nodes/seu-node/status

# Verificar logs
ssh root@seu-node "qm status <VMID>"
```

#### **"SSH não conecta"**
```bash
# Limpar known_hosts
./scripts/clean-ssh-keys.sh

# Verificar chave SSH
ssh-add ~/.ssh/k8s-cluster-key
```

#### **"Cluster não forma"**
```bash
# Logs do kubelet
ssh -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_MASTER> "sudo journalctl -u kubelet -f"

# Reexecutar Ansible se necessário
cd ansible && ansible-playbook -i inventory site.yml
```

### 🚑 **Comandos de Emergência**
```bash
# Reiniciar tudo
terraform destroy
terraform apply
cd ansible && ansible-playbook -i inventory site.yml && cd ..

# Reconfigurar apenas (sem destruir VMs)
cd ansible && ansible-playbook -i inventory site.yml

# Debug completo
terraform show
kubectl --kubeconfig=./kubeconfig get pods -A
```

---

## 🎯 **Casos de Uso Específicos**

### 🏫 **Para Laboratório/Educação**
```bash
# Configuração mínima de recursos
echo 'master_memory = 4096' >> terraform.tfvars
echo 'worker_memory = 8192' >> terraform.tfvars
echo 'environment = "development"' >> terraform.tfvars
```

### 🏢 **Para Produção**
```bash
# Configuração robusta
echo 'master_memory = 16384' >> terraform.tfvars  
echo 'worker_memory = 32768' >> terraform.tfvars
echo 'worker_count = 5' >> terraform.tfvars
echo 'environment = "production"' >> terraform.tfvars
```

### 🔗 **Para Integração CI/CD**
```bash
# Usar variáveis de ambiente
export TF_VAR_proxmox_api_token_secret="token-from-ci"
export TF_VAR_cluster_name="k8s-ci-$(date +%Y%m%d)"

# Deploy automatizado
terraform init && terraform apply
cd ansible && ansible-playbook -i inventory site.yml && cd ..
```

---

## 🎉 **Próximos Passos**

### 🚀 **Após Instalação**
1. **Deploy primeira app**: `./scripts/deploy-example.sh`
2. **Configure monitoring**: Prometheus + Grafana
3. **Setup backup**: Longhorn ou external
4. **Implemente CI/CD**: GitLab/Jenkins integration

### 📚 **Documentação Adicional**
- `README.md` - Documentação completa
- `OVERVIEW.md` - Visão geral do projeto
- `BEST-PRACTICES.md` - Melhores práticas
- `docs/` - Documentação técnica

---

<div align="center">

**⚡ Seu cluster Kubernetes está pronto em minutos!**

🚀 **Deploy** → 🔧 **Configure** → 🎯 **Use**

[![Terraform + Ansible](https://img.shields.io/badge/Powered%20by-Terraform%20%2B%20Ansible-blue)](https://terraform.io)

</div>

## 📊 Configuração Padrão

| Componente | IP | Recursos |
|------------|----|---------| 
| **Master** | 192.168.1.10 | 4 vCPU, 8GB RAM, 80GB |
| **Worker 1** | 192.168.1.20 | 4 vCPU, 16GB RAM, 50GB |
| **Worker 2** | 192.168.1.21 | 4 vCPU, 16GB RAM, 50GB |

## 🛠️ Comandos Essenciais

### **Gestão do Cluster**
```bash
terraform show                                 # Status geral
kubectl --kubeconfig=./kubeconfig get pods -A  # Ver logs/estado
./scripts/validate-cluster.sh                  # Validar configuração
scp -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_MASTER>:/home/<VM_USER>/.kube/config ./kubeconfig  # Baixar kubeconfig
```

### **Acesso SSH**
```bash
ssh -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_MASTER>     # Master node
ssh -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_WORKER_1>   # Worker 1
ssh -i ~/.ssh/k8s-cluster-key <VM_USER>@<IP_WORKER_2>   # Worker 2
```

### **Manutenção**
```bash
./scripts/clean-ssh-keys.sh   # Limpar known_hosts
terraform destroy             # Destruir cluster
rm -f ansible/inventory ./kubeconfig .terraform.lock.hcl  # Limpar arquivos temp
```

## 🔍 Verificações Rápidas

### **Status do Cluster Proxmox**
```bash
# Ver nós do cluster
pvecm nodes

# Templates por nó
pvesh get /cluster/resources --type vm | grep template

# Storage disponível
pvesh get /nodes/{node}/storage
```

### **Status do Kubernetes**
```bash
# Nós do cluster
kubectl --kubeconfig=./ansible/kubeconfig get nodes -o wide

# Pods do sistema
kubectl --kubeconfig=./ansible/kubeconfig get pods -A
```

## 📋 Decisão por Tamanho de Cluster

| Tamanho | Nós | Estratégia | Comando |
|---------|-----|------------|---------|
| **Pequeno** | 1-3 | Template em 1 nó | `./scripts/create-template.sh single` |
| **Médio** | 3-6 | Templates em 2-3 nós | `./scripts/create-template.sh auto` |
| **Grande** | 6+ | Storage compartilhado ou múltiplos templates | `./scripts/create-template.sh node1,node2,node3` |

## ⚡ Quick Start

```bash
# 1. Criar template (escolha um método acima)
./scripts/create-template.sh

# 2. Configurar nó no terraform.tfvars
proxmox_node = "your-node-here"

# 3. Executar projeto
terraform init
terraform apply

# 4. Verificar cluster
./scripts/validate-cluster.sh
```

## 🔍 Verificações Úteis

### **Ver nós do cluster:**
```bash
pvecm nodes
```

### **Listar templates por nó:**
```bash
# Em todos os nós
pvesh get /cluster/resources --type vm | grep template

# Em nó específico
ssh root@{node} "qm list | grep template"
```

### **Verificar storage:**
```bash
pvesh get /nodes/{node}/storage
```

## ⚠️ Pontos Importantes

### **1. Template + Nó devem corresponder**
```hcl
# Se template está no "proxmox-node1"
proxmox_node = "proxmox-node1"  # ✅ Correto

proxmox_node = "proxmox-node2"  # ❌ Erro - template não existe aqui
```

### **2. Storage considerations**
- **local-lvm**: Template fica local no nó
- **shared storage**: Template disponível em todos os nós
- **Verifique o tipo** do seu storage

### **3. Distribuição de carga**
Para clusters maiores, considere:
- Criar templates em múltiplos nós
- Distribuir VMs entre nós
- Usar storage compartilhado quando possível

## 🛠️ Troubleshooting

### **Template não encontrado:**
```bash
# Verificar se template existe no nó correto
ssh root@$PROXMOX_NODE "qm list | grep ubuntu-22.04-cloud"

# Se não existe, criar:
./scripts/create-template.sh
```

### **Nó não acessível:**
```bash
# Testar conectividade
ping {your-proxmox-node}
ssh root@{your-proxmox-node} "echo OK"

# Verificar se nó está no cluster
pvecm nodes
```

### **Storage insuficiente:**
```bash
# Verificar espaço
pvesh get /nodes/{node}/storage/{storage}/status

# Limpar templates antigos se necessário
qm destroy {template-id}
```

---

## 🎉 Resumo

✅ **Template pode ser criado em qualquer nó**  
✅ **Script automatizado facilita o processo**  
✅ **Configuração simples no terraform.tfvars**  
✅ **Funciona em clusters de qualquer tamanho**  

**O importante é:** Template criado ↔ Nó configurado no Terraform 🎯
