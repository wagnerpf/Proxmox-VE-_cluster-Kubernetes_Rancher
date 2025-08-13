# Configuração do Terraform
terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc9"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}

# Provider Proxmox VE via API Token
provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# Locals para cálculo de IPs e configurações
locals {
  master_ips = var.master_ips
  worker_ips = var.worker_ips

  # Tags padrão para todas as VMs
  common_tags = [
    "environment-${var.environment}",
    "project-${var.cluster_name}",
    "managed-by-terraform"
  ]

  # Path da chave SSH (configurável via variável)
  ssh_public_key_path = var.ssh_public_key_path != "" ? var.ssh_public_key_path : "~/.ssh/k8s-cluster-key.pub"
}

# VMs Master do Kubernetes
resource "proxmox_vm_qemu" "k8s_master" {
  count       = var.master_count
  name        = "${var.cluster_name}-master-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  # Configurações de hardware
  memory = var.master_memory
  scsihw = "virtio-scsi-pci"
  cpu {
    cores   = var.master_cpu
    sockets = 1
  }

  # Configurações de disco
  disk {
    storage = var.storage_pool
    type    = "disk"
    size    = var.master_disk_size
    slot    = "scsi0"
  }

  # Disco Cloud-init
  disk {
    storage = var.storage_pool
    type    = "cloudinit"
    slot    = "scsi1"
  }

  # Configurações de rede
  network {
    model  = "virtio"
    bridge = var.network_bridge
    id     = 0
  }

  # Cloud-init
  os_type      = "cloud-init"
  ciuser       = var.vm_user
  cipassword   = var.vm_password
  ipconfig0    = "ip=${local.master_ips[count.index]}/20,gw=${var.network_gateway}"
  nameserver   = var.dns_servers
  searchdomain = var.search_domain
  sshkeys      = file(local.ssh_public_key_path)

  # Configurações básicas
  agent  = 1
  tags   = join(";", concat(local.common_tags, ["kubernetes", "master", "control-plane"]))
  onboot = true
}

# VMs Worker do Kubernetes
resource "proxmox_vm_qemu" "k8s_worker" {
  count       = var.worker_count
  name        = "${var.cluster_name}-worker-${count.index + 1}"
  target_node = var.proxmox_node
  clone       = var.template_name
  full_clone  = true

  # Configurações de hardware
  memory = var.worker_memory
  scsihw = "virtio-scsi-pci"
  cpu {
    cores   = var.worker_cpu
    sockets = 1
  }

  # Configurações de disco
  disk {
    storage = var.storage_pool
    type    = "disk"
    size    = var.worker_disk_size
    slot    = "scsi0"
  }

  # Disco Cloud-init
  disk {
    storage = var.storage_pool
    type    = "cloudinit"
    slot    = "scsi1"
  }

  # Configurações de rede
  network {
    model  = "virtio"
    bridge = var.network_bridge
    id     = 0
  }

  # Cloud-init
  os_type      = "cloud-init"
  ciuser       = var.vm_user
  cipassword   = var.vm_password
  ipconfig0    = "ip=${local.worker_ips[count.index]}/20,gw=${var.network_gateway}"
  nameserver   = var.dns_servers
  searchdomain = var.search_domain
  sshkeys      = file(local.ssh_public_key_path)

  # Configurações básicas
  agent  = 1
  tags   = join(";", concat(local.common_tags, ["kubernetes", "worker", "worker-node"]))
  onboot = true

  # Dependência dos masters
  depends_on = [proxmox_vm_qemu.k8s_master]
}

# Inventário Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/ansible/inventory.tpl", {
    masters = [
      for i in range(var.master_count) : {
        name = "${var.cluster_name}-master-${i + 1}"
        ip   = local.master_ips[i]
      }
    ]
    workers = [
      for i in range(var.worker_count) : {
        name = "${var.cluster_name}-worker-${i + 1}"
        ip   = local.worker_ips[i]
      }
    ]
    ssh_user = var.vm_user
    # Removendo senha do inventário por segurança - usar apenas SSH keys
    ssh_password = "" # Use SSH keys instead
  })
  filename        = "${path.module}/ansible/inventory"
  file_permission = "0644"

  depends_on = [
    proxmox_vm_qemu.k8s_master,
    proxmox_vm_qemu.k8s_worker
  ]
}
