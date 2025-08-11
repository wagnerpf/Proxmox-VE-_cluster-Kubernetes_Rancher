#!/bin/bash

# Script para fazer deploy de aplicação de exemplo no cluster

set -e

echo "=== Fazendo deploy de aplicação de exemplo ==="

# Verificar se kubeconfig existe
if [ ! -f "./kubeconfig" ]; then
    echo "Arquivo kubeconfig não encontrado."
    echo "Execute primeiro o script check-cluster.sh"
    exit 1
fi

# Criar namespace para aplicação
kubectl --kubeconfig=./kubeconfig create namespace demo --dry-run=client -o yaml | kubectl --kubeconfig=./kubeconfig apply -f -

# Deploy do nginx
cat <<EOF | kubectl --kubeconfig=./kubeconfig apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  namespace: demo
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "128Mi"
            cpu: "100m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-demo-service
  namespace: demo
spec:
  selector:
    app: nginx-demo
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
  type: NodePort
EOF

echo ""
echo "--- Aguardando pods ficarem prontos ---"
kubectl --kubeconfig=./kubeconfig wait --for=condition=Ready pods -l app=nginx-demo -n demo --timeout=300s

echo ""
echo "--- Status do deployment ---"
kubectl --kubeconfig=./kubeconfig get deployments -n demo
kubectl --kubeconfig=./kubeconfig get pods -n demo
kubectl --kubeconfig=./kubeconfig get services -n demo

echo ""
echo "=== Deploy concluído ==="
echo "Aplicação disponível em: http://<NODE_IP>:30080"
