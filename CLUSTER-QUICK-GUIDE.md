# 🎯 Guia Rápido: Cluster Kubernetes no Proxmox VE

## ✅ Implantação Completa em 5 Passos

### **1. 🔑 Preparar SSH Keys**
```bash
# Gerar chave SSH dedicada para o cluster
ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key -C "k8s-cluster@$(hostname)"

# Verificar criação
ls -la ~/.ssh/k8s-cluster-key*
```

### **2. 📦 Criar Template Ubuntu 22.04**
```bash
# Opção A: Script automatizado (Recomendado)
./scripts/create-template.sh single

# Opção B: Manual no Proxmox
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-22.04-cloud --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --scsi1 local-lvm:cloudinit
qm set 9000 --vga qxl --agent enabled=1
qm template 9000
```

### **3. ⚙️ Configurar Variáveis**
```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

```hcl
# Configurações essenciais
proxmox_api_url          = "https://your-proxmox-server.domain.com:8006/api2/json"
proxmox_api_token_id     = "your-user@pve!your-token-name"
proxmox_api_token_secret = "SEU_TOKEN_AQUI"
proxmox_node             = "your-proxmox-node"

# Cluster
cluster_name = "my-k8s-cluster"
environment  = "production"

# SSH
ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
vm_user            = "ubuntu"

# IPs fixos (ajustar para sua rede)
master_ips = ["192.168.1.10"]
worker_ips = ["192.168.1.20", "192.168.1.21"]
```

### **4. 🚀 Executar Instalação**
```bash
# Instalação completa automatizada
make prerequisites  # Instalar dependências
make install       # Provisionar + configurar cluster

# OU passo a passo
make init
make plan
make apply
```

### **5. ✅ Verificar e Acessar**
```bash
# Verificar cluster
make check

# Acessar Rancher
# URL: https://192.168.1.10:8443
# User: admin / Pass: admin123

# SSH nos nós
make ssh-master
make ssh-worker-1
```

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
