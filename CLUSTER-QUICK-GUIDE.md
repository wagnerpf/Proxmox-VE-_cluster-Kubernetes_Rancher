# ⚡ Guia Rápido: Kubernetes + Rancher no Proxmox VE

> **Deploy completo em 15 minutos** - Cluster Kubernetes empresarial com interface Rancher

## 🎯 **Setup Rápido - 4 Comandos**

```bash
# 1️⃣ Preparar autenticação
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key

# 2️⃣ Configurar projeto  
cp terraform.tfvars.example terraform.tfvars && nano terraform.tfvars

# 3️⃣ Instalação completa
make install

# 4️⃣ Acessar Rancher
open https://172.17.176.34:8443  # admin / admin123
```

**⏱️ Tempo total:** 15-20 minutos

---

## 📋 **Pré-requisitos Essenciais**

### ✅ **Checklist Básico**
- [ ] **Proxmox VE** 7.0+ funcionando
- [ ] **Template Ubuntu 22.04** criado no nó "gardenia"  
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
curl -k https://cacto.cefetes.br:8006/api2/json/version
```

---

## ⚙️ **Configuração Essencial**

### 📝 **Arquivo terraform.tfvars (Mínimo)**

```hcl
# === PROXMOX CONNECTION ===
proxmox_api_url          = "https://cacto.cefetes.br:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"  
proxmox_api_token_secret = "SEU_TOKEN_AQUI"
proxmox_node             = "gardenia"

# === CLUSTER CONFIG ===
cluster_name = "k8s-cluster-viana"
environment  = "production"

# === NETWORK (CEFETES) ===
master_ips = ["172.17.176.34"]
worker_ips = ["172.17.176.35", "172.17.176.36"]

# === SSH SECURITY ===
ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
vm_user            = "admviana"
```

---

## 🚀 **Instalação Express**

### 🏃‍♂️ **Método Ultra-Rápido**
```bash
# Clone + Setup + Deploy em uma linha
git clone <repo> && cd terraform-proxmox-k8s && make install
```

### 🎛️ **Método com Controle**
```bash
# 1. Preparar ambiente
make prerequisites

# 2. Inicializar Terraform  
make init

# 3. Revisar plano (opcional)
make plan

# 4. Aplicar infraestrutura
make apply

# 5. Verificar resultado
make validate
```

---

## 📊 **Resultado Esperado**

### 🖥️ **Infraestrutura Criada**
```
✅ 3 VMs Ubuntu 22.04 no Proxmox
   ├── k8s-cluster-viana-master-1  (172.17.176.34)
   ├── k8s-cluster-viana-worker-1  (172.17.176.35)  
   └── k8s-cluster-viana-worker-2  (172.17.176.36)

✅ Cluster Kubernetes v1.28.2
   ├── Control plane configurado
   ├── Workers unidos ao cluster
   └── Flannel CNI funcionando

✅ Rancher v2.7.5+ instalado
   ├── Interface web: https://172.17.176.34:8443
   ├── Credenciais: admin / admin123
   └── cert-manager para certificados
```

### 🔗 **Pontos de Acesso**
| Serviço | URL | Credenciais |
|---------|-----|-------------|
| **Rancher UI** | `https://172.17.176.34:8443` | `admin` / `admin123` |
| **Kubernetes API** | `https://172.17.176.34:6443` | Via kubeconfig |
| **SSH Master** | `ssh admviana@172.17.176.34` | Chave SSH |

---

## ✅ **Verificações Pós-Deploy**

### 🔍 **Comandos de Verificação**
```bash
# Status geral
make validate

# Conectividade SSH
make ping  

# Cluster Kubernetes
kubectl --kubeconfig=./kubeconfig get nodes

# Pods do sistema
kubectl --kubeconfig=./kubeconfig get pods -A

# Status do Rancher
kubectl --kubeconfig=./kubeconfig get pods -n cattle-system
```

### 📋 **Saída Esperada**
```bash
$ kubectl get nodes
NAME                         STATUS   ROLES           AGE   VERSION
k8s-cluster-viana-master-1   Ready    control-plane   5m    v1.28.2
k8s-cluster-viana-worker-1   Ready    <none>          4m    v1.28.2  
k8s-cluster-viana-worker-2   Ready    <none>          4m    v1.28.2

$ kubectl get pods -n cattle-system
NAME                       READY   STATUS    RESTARTS   AGE
rancher-6f4c8c5d4b-xyz12   1/1     Running   0          3m
rancher-6f4c8c5d4b-abc34   1/1     Running   0          3m
rancher-6f4c8c5d4b-def56   1/1     Running   0          3m
```

---

## 🛠️ **Comandos de Gestão**

### 📊 **Monitoramento**
```bash
make status          # Status completo da infraestrutura
make logs           # Logs de deployment  
make check          # Verificação rápida
```

### 🔧 **Acesso e Configuração**
```bash
make ssh-master     # SSH no master node
make get-kubeconfig # Baixar kubeconfig
make rancher-info   # Informações do Rancher
```

### 🧹 **Manutenção**
```bash
make clean-ssh-keys # Limpar known_hosts (VMs recriadas)
make destroy        # Destruir toda infraestrutura
make clean          # Limpar arquivos temporários
```

---

## 🆘 **Troubleshooting Rápido**

### ❌ **Problemas Comuns**

#### **"Template não encontrado"**
```bash
# Verificar se template existe no nó correto
ssh root@gardenia "qm list | grep ubuntu-22.04-cloud"

# Se não existe, criar:
./scripts/create-template.sh
```

#### **"VMs não inicializam"**  
```bash
# Verificar recursos no Proxmox
pvesh get /nodes/gardenia/status

# Verificar logs
ssh root@gardenia "qm status <VMID>"
```

#### **"SSH não conecta"**
```bash
# Limpar known_hosts
make clean-ssh-keys

# Verificar chave SSH
ssh-add ~/.ssh/k8s-cluster-key
```

#### **"Cluster não forma"**
```bash
# Logs do kubelet
ssh -i ~/.ssh/k8s-cluster-key admviana@172.17.176.34 "sudo journalctl -u kubelet -f"

# Reexecutar Ansible se necessário
cd ansible && ansible-playbook -i inventory site.yml
```

### 🚑 **Comandos de Emergência**
```bash
# Reiniciar tudo
make destroy && make install

# Reconfigurar apenas (sem destruir VMs)
cd ansible && ansible-playbook -i inventory site.yml

# Debug completo
make status && make logs
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
make install
```

---

## 🎉 **Próximos Passos**

### 🚀 **Após Instalação**
1. **Explore Rancher**: Apps, Projects, Users
2. **Deploy primeira app**: Via Rancher Apps Catalog
3. **Configure monitoring**: Prometheus + Grafana
4. **Setup backup**: Longhorn ou external
5. **Implemente CI/CD**: GitLab/Jenkins integration

### 📚 **Documentação Adicional**
- `README.md` - Documentação completa
- `OVERVIEW.md` - Visão geral do projeto
- `BEST-PRACTICES.md` - Melhores práticas
- `docs/` - Documentação técnica

---

<div align="center">

**⚡ Seu cluster Kubernetes está pronto em minutos!**

🚀 **Deploy** → 🔧 **Configure** → 🎯 **Use**

[![Powered by CEFET-ES](https://img.shields.io/badge/Powered%20by-CEFET--ES-blue)](https://cefetes.br)

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
make status           # Status geral
make logs            # Ver logs
make validate        # Validar configuração
make get-kubeconfig  # Baixar kubeconfig
```

### **Acesso SSH**
```bash
make ssh-master      # Master node
make ssh-worker-1    # Worker 1
make ssh-worker-2    # Worker 2
```

### **Manutenção**
```bash
make clean-ssh-keys  # Limpar known_hosts
make destroy         # Destruir cluster
make clean           # Limpar arquivos temp
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

# Rancher status
kubectl --kubeconfig=./ansible/kubeconfig get pods -n cattle-system
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
make create-template

# 2. Configurar nó no terraform.tfvars
proxmox_node = "your-node-here"

# 3. Executar projeto
make init
make apply

# 4. Acessar Rancher
make rancher-info
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
make create-template
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
