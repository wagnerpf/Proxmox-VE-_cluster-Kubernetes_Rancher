#!/bin/bash

# Script para configurar o nó master do Kubernetes

set -e

echo "=== Configurando nó master do Kubernetes ==="

# Obter IP da interface principal
MASTER_IP=$(hostname -I | awk '{print $1}')

# Inicializar cluster Kubernetes
sudo kubeadm init \
  --apiserver-advertise-address=${MASTER_IP} \
  --pod-network-cidr=10.244.0.0/16 \
  --cri-socket=unix:///var/run/containerd/containerd.sock

# Configurar kubectl para o usuário ubuntu
mkdir -p /home/ubuntu/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config

# Instalar Flannel para rede de pods
kubectl --kubeconfig=/home/ubuntu/.kube/config apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Aguardar pods do sistema ficarem prontos
echo "Aguardando pods do sistema ficarem prontos..."
kubectl --kubeconfig=/home/ubuntu/.kube/config wait --for=condition=Ready pods --all -n kube-system --timeout=300s

# Gerar comando de join para workers
JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo "${JOIN_COMMAND}" > /home/ubuntu/join-command.txt
sudo chown ubuntu:ubuntu /home/ubuntu/join-command.txt

echo "=== Nó master configurado com sucesso ==="
echo "Comando de join salvo em: /home/ubuntu/join-command.txt"
echo "Comando: ${JOIN_COMMAND}"
