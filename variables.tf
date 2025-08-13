# ========================================
# CONFIGURAÇÕES PROXMOX VE API
# ========================================

variable "proxmox_api_url" {
  description = "URL da API do Proxmox VE"
  type        = string
  default     = "https://exemplo.com:8006/api2/json"
}

variable "proxmox_api_token_id" {
  description = "ID do token de API do Proxmox VE (formato: user@pve!token-name)"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Secret do token de API do Proxmox VE"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Ignorar certificados TLS inválidos"
  type        = bool
  default     = true
}

variable "proxmox_node" {
  description = "Nome do nó Proxmox onde criar as VMs"
  type        = string
  default     = "nome do nó"
}

# ========================================
# CONFIGURAÇÕES DO TEMPLATE
# ========================================

variable "template_name" {
  description = "Nome do template Ubuntu no Proxmox"
  type        = string
  default     = "ubuntu-22.04-cloud"
}

# ========================================
# CONFIGURAÇÕES DO CLUSTER
# ========================================

variable "cluster_name" {
  description = "Nome do cluster Kubernetes"
  type        = string
  default     = "k8s-cluster"
}

variable "master_count" {
  description = "Número de nós master"
  type        = number
  default     = 1

  validation {
    condition     = var.master_count > 0 && var.master_count <= 5
    error_message = "Master count deve estar entre 1 e 5."
  }
}

variable "worker_count" {
  description = "Número de nós worker"
  type        = number
  default     = 2

  validation {
    condition     = var.worker_count >= 0 && var.worker_count <= 10
    error_message = "Worker count deve estar entre 0 e 10."
  }
}

# ========================================
# CONFIGURAÇÕES DE HARDWARE - MASTER
# ========================================

variable "master_memory" {
  description = "Memória RAM para nós master (MB)"
  type        = number
  default     = 8192

  validation {
    condition     = var.master_memory >= 4096
    error_message = "Master nodes precisam de pelo menos 4GB (4096MB) de RAM."
  }
}

variable "master_cpu" {
  description = "Número de CPUs para nós master"
  type        = number
  default     = 4

  validation {
    condition     = var.master_cpu >= 2 && var.master_cpu <= 16
    error_message = "Master CPU deve estar entre 2 e 16 cores."
  }
}

variable "master_disk_size" {
  description = "Tamanho do disco para nós master"
  type        = string
  default     = "80G"
}

# ========================================
# CONFIGURAÇÕES DE HARDWARE - WORKER
# ========================================

variable "worker_memory" {
  description = "Memória RAM para nós worker (MB)"
  type        = number
  default     = 16384
}

variable "worker_cpu" {
  description = "Número de CPUs para nós worker"
  type        = number
  default     = 4
}

variable "worker_disk_size" {
  description = "Tamanho do disco para nós worker"
  type        = string
  default     = "50G"
}

# ========================================
# CONFIGURAÇÕES DE REDE
# ========================================

variable "network_bridge" {
  description = "Bridge de rede no Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Gateway da rede"
  type        = string
  default     = "192.168.1.1"
}

variable "dns_servers" {
  description = "Servidores DNS"
  type        = string
  default     = "8.8.4.4"
}

variable "search_domain" {
  description = "Domínio de busca"
  type        = string
  default     = "local"
}

# ========================================
# CONFIGURAÇÕES DE IP
# ========================================

variable "master_ips" {
  description = "IPs específicos para masters"
  type        = list(string)
  default     = ["192.168.1.10"]
}

variable "worker_ips" {
  description = "IPs específicos para workers"
  type        = list(string)
  default     = ["192.168.1.35", "192.168.1.36"]
}

# ========================================
# CONFIGURAÇÕES DE ARMAZENAMENTO
# ========================================

variable "storage_pool" {
  description = "Pool de armazenamento no Proxmox"
  type        = string
  default     = "local-lvm"
}

# ========================================
# CONFIGURAÇÕES DE USUÁRIO VM
# ========================================

variable "vm_user" {
  description = "Usuário para as VMs"
  type        = string
  default     = "admviana"
}

variable "vm_password" {
  description = "Senha para as VMs"
  type        = string
  sensitive   = true
  default     = "abc@123"
}

# ========================================
# CONFIGURAÇÕES ADICIONAIS
# ========================================

variable "environment" {
  description = "Ambiente de implantação"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment deve ser: development, staging ou production."
  }
}

variable "ssh_public_key_path" {
  description = "Caminho para a chave SSH pública"
  type        = string
  default     = "~/.ssh/k8s-cluster-key.pub"

  validation {
    condition     = can(regex("^.*\\.pub$", var.ssh_public_key_path))
    error_message = "SSH public key path deve terminar com .pub."
  }
}
