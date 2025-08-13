# 🔧 Configuração de IPs - Exemplos Práticos

## 🎯 Como configurar IPs das VMs

### **Opção 1: IPs Automáticos (Padrão) ✅**
```hcl
# terraform.tfvars
ip_assignment_mode = "auto"  # ou omitir (é o padrão)
network_cidr       = "<SEU_CIDR>"

# IPs serão:
# Master:  <exemplo: 192.168.1.10>
# Worker1: <exemplo: 192.168.1.20>
# Worker2: <exemplo: 192.168.1.21>
```

### **Opção 2: IPs Específicos (Manual)**
```hcl
# terraform.tfvars
ip_assignment_mode = "manual"
network_cidr       = "<SEU_CIDR>"

# IPs específicos
master_ips = ["<IP_MASTER>"]
worker_ips = ["<IP_WORKER1>", "<IP_WORKER2>"]
```

### **Opção 3: IPs Automáticos Personalizados**
```hcl
# terraform.tfvars
ip_assignment_mode    = "auto"
network_cidr          = "<SEU_CIDR>"
auto_ip_start_master  = <INICIO_MASTER>
auto_ip_start_worker  = <INICIO_WORKER>

# IPs serão:
# Master:  <exemplo: 192.168.1.50>
# Worker1: <exemplo: 192.168.1.100>
# Worker2: <exemplo: 192.168.1.101>
```

## 📋 Configuração Atual (Baseada no seu variables.tf)

Com suas configurações atuais:
```hcl
# Seus valores atuais
network_cidr = "<SEU_CIDR>"
master_count = <QTD_MASTERS>
worker_count = <QTD_WORKERS>

# IPs automáticos resultantes:
# Master 1: <exemplo: 192.168.1.10>
# Worker 1: <exemplo: 192.168.1.20>
# Worker 2: <exemplo: 192.168.1.21>
```

## 🛠️ Cenários Comuns

### **Cenário 1: Produção com IPs fixos conhecidos**
```hcl
ip_assignment_mode = "manual"
master_ips = ["<IP_MASTER>"]
worker_ips = ["<IP_WORKER1>", "<IP_WORKER2>", "<IP_WORKER3>"]
master_count = 1
worker_count = 3
```

### **Cenário 2: Desenvolvimento com IPs automáticos**
```hcl
ip_assignment_mode = "auto"
network_cidr = "<SEU_CIDR>"
auto_ip_start_master = <INICIO_MASTER>
auto_ip_start_worker = <INICIO_WORKER>
```

### **Cenário 3: Laboratório com range específico**
```hcl
ip_assignment_mode = "auto"
network_cidr = "<SEU_CIDR>"
auto_ip_start_master = <INICIO_MASTER>
auto_ip_start_worker = <INICIO_WORKER>
```

## 🔍 Verificar IPs antes de aplicar

```bash
# Ver quais IPs serão atribuídos
terraform plan

# Ou verificar outputs específicos
terraform output computed_master_ips
terraform output computed_worker_ips
terraform output ip_assignment_summary
```

## ⚠️ Validações Automáticas

O sistema valida automaticamente:
- **Número de IPs** corresponde ao número de VMs
- **IPs únicos** (sem duplicatas)
- **IPs válidos** no CIDR especificado

## 🚀 Exemplos Prontos

### **Modo automático (recomendado)**
```hcl
ip_assignment_mode = "auto"
network_cidr = "<SEU_CIDR>"
network_gateway = "<SEU_GATEWAY>"

# Resultado:
# Master:  <exemplo: 192.168.1.10>
# Worker1: <exemplo: 192.168.1.20>
# Worker2: <exemplo: 192.168.1.21>
```

### **Modo manual para IPs específicos:**
```hcl
ip_assignment_mode = "manual"
network_cidr = "<SEU_CIDR>"
master_ips = ["<IP_MASTER>"]
worker_ips = ["<IP_WORKER1>", "<IP_WORKER2>"]
```

---

## 💡 Recomendação

Para sua situação, sugiro **manter o modo automático** que já está funcionando bem. Se precisar de IPs específicos no futuro, é só alterar para modo manual.

**Seus IPs atuais (automáticos):**
- Master: `<IP_MASTER>`
- Worker 1: `<IP_WORKER1>`
- Worker 2: `<IP_WORKER2>`

Estes IPs são calculados automaticamente e funcionam perfeitamente! 🎯
