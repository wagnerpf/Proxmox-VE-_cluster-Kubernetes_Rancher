# 📋 Changelog - Infraestrutura Kubernetes

## [2025-01-11] - Implementação de Melhores Práticas Terraform

### 🚀 **UPGRADE PRINCIPAL: Melhores Práticas de Segurança e Organização**

#### ✅ **Segurança Aprimorada**

##### **1. SSH Key Authentication**
- **Nova variável**: `ssh_public_key_path` configurável
- **Path padrão**: `~/.ssh/k8s-cluster-key.pub`
- **Remoção**: Senhas do inventário Ansible (uso apenas SSH keys)
- **Benefício**: Autenticação mais segura e controle centralizado

##### **2. Variáveis Sensíveis**
- **Marcação**: `proxmox_api_token_secret` e `vm_password` como `sensitive = true`
- **Outputs seguros**: Senhas não expostas nos outputs
- **Validações**: Prevenção de configurações inseguras

#### ✅ **Tags Padronizadas**

##### **Sistema de Tags Consistente**
```hcl
common_tags = [
  "environment=${var.environment}",    # production/staging/development
  "project=${var.cluster_name}",       # Nome do projeto
  "managed-by=terraform"               # Identificação de gestão
]

# Aplicadas em todas as VMs:
- kubernetes;master;node-type=control-plane  # Masters
- kubernetes;worker;node-type=worker          # Workers
```

#### ✅ **Validações Robustas**

##### **Novas Validações Implementadas**
- **Environment**: Deve ser `development`, `staging` ou `production`
- **Master Count**: Entre 1 e 5 nós
- **Worker Count**: Entre 0 e 10 nós
- **Master Memory**: Mínimo 4GB (4096MB)
- **Master CPU**: Entre 2 e 16 cores
- **SSH Key Path**: Deve terminar com `.pub`

#### ✅ **Outputs Melhorados**

##### **Novos Outputs Informativos**
- **Rancher Access**: URL e credenciais (sem expor senha)
- **kubectl Config**: Comando para configurar kubeconfig
- **SSH Key Path**: Path da chave utilizada
- **Cluster Tags**: Tags aplicadas aos recursos

#### ✅ **Organização Estrutural**

##### **Locals Centralizados**
- **Configurações**: IPs, tags e paths centralizados
- **Reutilização**: Configurações consistentes entre recursos
- **Manutenibilidade**: Alterações em local único

##### **Formatação e Validação**
- **terraform fmt**: Código formatado consistentemente
- **terraform validate**: Configuração validada
- **Comentários**: Documentação clara no código

#### ✅ **Documentação Atualizada**

##### **Novos Arquivos**
- **BEST-PRACTICES.md**: Guia completo das melhorias
- **terraform.tfvars.example**: Exemplo atualizado e documentado

##### **Arquivos Atualizados**
- **README.md**: Instruções com as novas práticas
- **variables.tf**: Validações e documentação aprimorada
- **outputs.tf**: Outputs seguros e informativos

#### 📊 **Comparativo: Antes vs Depois**

| Aspecto | Antes | Depois |
|---------|-------|--------|
| **Segurança** | ❌ Senhas em texto plano | ✅ SSH keys exclusivo |
| **Tags** | ❌ Tags inconsistentes | ✅ Sistema padronizado |
| **Validações** | ❌ Sem validações | ✅ Validações robustas |
| **Paths** | ❌ Hardcoded | ✅ Configurável |
| **Outputs** | ❌ Básicos | ✅ Informativos e seguros |
| **Organização** | ❌ Código duplicado | ✅ Locals centralizados |

#### 🎯 **Impacto das Melhorias**

##### **Segurança**
- ✅ Redução de 100% em senhas expostas
- ✅ Autenticação baseada apenas em chaves SSH
- ✅ Validações que previnem configurações inseguras

##### **Manutenibilidade**
- ✅ Tags padronizadas para billing e gestão
- ✅ Configurações centralizadas em locals
- ✅ Validações que previnem erros humanos

##### **Flexibilidade**
- ✅ Suporte a múltiplos ambientes (dev/staging/prod)
- ✅ Paths configuráveis via variáveis
- ✅ Validações que garantem configurações válidas

#### 🚀 **Novas Funcionalidades**

##### **Suporte a Ambientes**
```hcl
environment = "production"  # development, staging, production
```

##### **SSH Key Configurável**
```hcl
ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
```

##### **Comandos Make Aprimorados**
```bash
make prerequisites  # Instalar dependências
make install       # Instalação completa com delay otimizado
make validate      # Validar configuração
```

### 🔄 **Migração das Configurações Anteriores**

Para usuários existentes, as principais mudanças necessárias:

1. **Gerar chaves SSH dedicadas**:
   ```bash
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/k8s-cluster-key
   ```

2. **Atualizar terraform.tfvars**:
   ```hcl
   environment = "production"
   ssh_public_key_path = "~/.ssh/k8s-cluster-key.pub"
   ```

3. **Executar formatação**:
   ```bash
   terraform fmt
   terraform validate
   ```

## [2024-01-11] - Migração para Ubuntu 22.04 LTS

### 🔄 **Mudança Crítica: Ubuntu 24.04 → 22.04**

**Motivo**: Ubuntu 24.04 estava apresentando travamentos ao inicializar as máquinas virtuais no ambiente Proxmox VE.

#### ✅ **Mudanças Realizadas**

##### **1. Template de Imagem**
- **Antes**: `noble-server-cloudimg-amd64.img` (Ubuntu 24.04)
- **Depois**: `jammy-server-cloudimg-amd64.img` (Ubuntu 22.04)
- **Template Name**: `ubuntu-24.04-cloud` → `ubuntu-22.04-cloud`

##### **2. URLs de Download**
- **Antes**: `https://cloud-images.ubuntu.com/noble/current/`
- **Depois**: `https://cloud-images.ubuntu.com/jammy/current/`

##### **3. Arquivos Atualizados**
- ✅ `terraform.tfvars` - Nome do template
- ✅ `README.md` - Comandos e documentação
- ✅ `scripts/create-template.sh` - Script automatizado
- ✅ `UBUNTU-COMPARISON.md` - Comparação atualizada
- ✅ `PROXMOX-CLUSTER.md` - Instruções do cluster

#### 🚀 **Benefícios da Mudança**

- **Estabilidade**: Ubuntu 22.04 LTS é uma versão madura e testada
- **Compatibilidade**: Melhor compatibilidade com Proxmox VE
- **Confiabilidade**: Sem travamentos na inicialização
- **Suporte**: Suporte até 2027

## [2024-01-11] - Configuração SCSI para Cloud-init

### Mudanças Realizadas

#### ✅ **Configuração Principal (main.tf)**
- **Alteração**: Disco cloud-init movido de `ide2` para `scsi1`
- **Controlador SCSI**: Adicionado `scsihw = "virtio-scsi-pci"` para melhor performance
- **Benefícios**:
  - Melhor performance de I/O
  - Consistência com o disco principal (scsi0)
  - Suporte nativo do virtio-scsi

#### ✅ **Documentação Atualizada**
- **README.md**: Comando de criação de template atualizado
- **scripts/create-template.sh**: Script automatizado corrigido  
- **UBUNTU-COMPARISON.md**: Instruções de comparação atualizadas
- **PROXMOX-CLUSTER.md**: Documentação do cluster corrigida

#### ✅ **Layout de Discos Atualizado**
```
Master/Worker VMs:
- scsi0: Disco principal do sistema (80G/50G)
- scsi1: Disco cloud-init (metadados)
- Controlador: virtio-scsi-pci
```

### Comandos Atualizados para Template

**Ubuntu 22.04:**
```bash
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

### Validação

✅ **Migração Ubuntu** - 24.04 → 22.04 LTS  
✅ **terraform plan** - Configuração validada  
✅ **Documentação** - Todos os arquivos atualizados  
✅ **Scripts** - Automação corrigida  

### Próximos Passos

1. **Recriar template** com Ubuntu 22.04 e configurações SCSI
2. **Aplicar infraestrutura** com `terraform apply`
3. **Validar conectividade** das VMs
4. **Executar Ansible** para instalar Kubernetes

### Notas Importantes

⚠️ **Template Existente**: Será necessário recriar o template usando Ubuntu 22.04 para resolver os problemas de travamento.

🔧 **Compatibilidade**: Ubuntu 22.04 LTS oferece melhor estabilidade em ambientes de virtualização.
