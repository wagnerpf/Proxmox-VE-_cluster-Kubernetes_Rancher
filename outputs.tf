# ========================================
# OUTPUTS DO CLUSTER KUBERNETES
# ========================================

output "cluster_info" {
  description = "Informações gerais do cluster"
  value = {
    cluster_name = var.cluster_name
    master_count = var.master_count
    worker_count = var.worker_count
    nodes_total  = var.master_count + var.worker_count
  }
}

output "master_nodes" {
  description = "Informações dos nós master"
  value = {
    for i in range(var.master_count) : i => {
      name = proxmox_vm_qemu.k8s_master[i].name
      ip   = var.master_ips[i]
      vmid = proxmox_vm_qemu.k8s_master[i].vmid
    }
  }
}

output "worker_nodes" {
  description = "Informações dos nós worker"
  value = {
    for i in range(var.worker_count) : i => {
      name = proxmox_vm_qemu.k8s_worker[i].name
      ip   = var.worker_ips[i]
      vmid = proxmox_vm_qemu.k8s_worker[i].vmid
    }
  }
}

output "ssh_connections" {
  description = "Comandos SSH para conectar nos nós"
  value = {
    masters = [
      for i in range(var.master_count) :
      "ssh ${var.vm_user}@${var.master_ips[i]}"
    ]
    workers = [
      for i in range(var.worker_count) :
      "ssh ${var.vm_user}@${var.worker_ips[i]}"
    ]
  }
}

output "ansible_inventory_path" {
  description = "Caminho para o inventário Ansible gerado"
  value       = local_file.ansible_inventory.filename
}

output "network_info" {
  description = "Informações de rede do cluster"
  value = {
    bridge  = var.network_bridge
    gateway = var.network_gateway
    dns     = var.dns_servers
    domain  = var.search_domain
  }
}

# ========================================
# OUTPUTS ADICIONAIS PARA MELHORES PRÁTICAS
# ========================================

output "ssh_key_path" {
  description = "Caminho da chave SSH pública utilizada"
  value       = local.ssh_public_key_path
}

output "cluster_tags" {
  description = "Tags aplicadas aos recursos"
  value       = local.common_tags
}

output "rancher_access" {
  description = "Informações de acesso ao Rancher"
  value = {
    url      = "https://${var.master_ips[0]}:8443"
    username = "admin"
    # Não expor senha nos outputs por segurança
    note = "Use 'admin123' como senha inicial"
  }
}

output "kubectl_config" {
  description = "Comando para configurar kubectl"
  value       = "scp ${var.vm_user}@${var.master_ips[0]}:~/.kube/config ~/.kube/config-${var.cluster_name}"
}
