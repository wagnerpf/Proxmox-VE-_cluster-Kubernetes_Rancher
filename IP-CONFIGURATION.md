# 🔧 Configuração de IPs - Exemplos Práticos

## 🎯 Como configurar IPs das VMs

### **Opção 1: IPs Automáticos (Padrão) ✅**
```hcl
# terraform.tfvars
ip_assignment_mode = "auto"  # ou omitir (é o padrão)
network_cidr       = "192.168.1.0/24"

# IPs serão:
# Master:  192.168.1.10
# Worker1: 192.168.1.20
# Worker2: 192.168.1.21
```

### **Opção 2: IPs Específicos (Manual)**
```hcl
# terraform.tfvars
ip_assignment_mode = "manual"
network_cidr       = "192.168.1.0/24"

# IPs específicos
master_ips = ["192.168.1.15"]
worker_ips = ["192.168.1.25", "192.168.1.26"]
```

### **Opção 3: IPs Automáticos Personalizados**
```hcl
# terraform.tfvars
ip_assignment_mode    = "auto"
network_cidr          = "172.17.176.0/24"
auto_ip_start_master  = 50  # Master começará em .50
auto_ip_start_worker  = 100 # Workers começarão em .100

# IPs serão:
# Master:  172.17.176.50
# Worker1: 172.17.176.100
# Worker2: 172.17.176.101
```

## 📋 Configuração Atual (Baseada no seu variables.tf)

Com suas configurações atuais:
```hcl
# Seus valores atuais
network_cidr = "172.17.176.0/24"
master_count = 1
worker_count = 2

# IPs automáticos resultantes:
# Master 1: 172.17.176.10
# Worker 1: 172.17.176.20
# Worker 2: 172.17.176.21
```

## 🛠️ Cenários Comuns

### **Cenário 1: Produção com IPs fixos conhecidos**
```hcl
ip_assignment_mode = "manual"
master_ips = ["172.17.176.50"]
worker_ips = ["172.17.176.60", "172.17.176.61", "172.17.176.62"]
master_count = 1
worker_count = 3
```

### **Cenário 2: Desenvolvimento com IPs automáticos**
```hcl
ip_assignment_mode = "auto"
network_cidr = "192.168.100.0/24"
auto_ip_start_master = 10
auto_ip_start_worker = 20
```

### **Cenário 3: Laboratório com range específico**
```hcl
ip_assignment_mode = "auto"
network_cidr = "10.0.1.0/24"
auto_ip_start_master = 100
auto_ip_start_worker = 200
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

### **Para sua rede atual (CEFET):**
```hcl
# Modo automático (recomendado)
ip_assignment_mode = "auto"
network_cidr = "172.17.176.0/24"
network_gateway = "172.17.176.1"

# Resultado:
# Master:  172.17.176.10
# Worker1: 172.17.176.20
# Worker2: 172.17.176.21
```

### **Modo manual para IPs específicos:**
```hcl
ip_assignment_mode = "manual"
network_cidr = "172.17.176.0/24"
master_ips = ["172.17.176.50"]
worker_ips = ["172.17.176.60", "172.17.176.61"]
```

---

## 💡 Recomendação

Para sua situação, sugiro **manter o modo automático** que já está funcionando bem. Se precisar de IPs específicos no futuro, é só alterar para modo manual.

**Seus IPs atuais (automáticos):**
- Master: `172.17.176.10`
- Worker 1: `172.17.176.20`
- Worker 2: `172.17.176.21`

Estes IPs são calculados automaticamente e funcionam perfeitamente! 🎯
