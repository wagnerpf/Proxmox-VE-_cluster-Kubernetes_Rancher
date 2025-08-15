# 💾 Volumes Persistentes com Longhorn

## 🎯 **Visão Geral**

Este guia mostra como usar volumes persistentes no seu cluster Kubernetes usando Longhorn, um sistema de storage distribuído desenvolvido pela Rancher.

## 🔧 **Instalação**

### **Método 1: Via Makefile (Recomendado)**
```bash
# Instalar Longhorn
make install-longhorn

# Testar instalação
make test-longhorn

# Verificar status
make longhorn-status

# Acessar interface web
make longhorn-ui
```

### **Método 2: Script Manual**
```bash
# Executar script diretamente
chmod +x scripts/install-longhorn.sh
./scripts/install-longhorn.sh

# Testar
chmod +x scripts/test-longhorn.sh
./scripts/test-longhorn.sh
```

## 📊 **Verificação da Instalação**

```bash
# Status completo
make longhorn-status

# Verificar storage classes
kubectl get storageclass

# Status dos pods
kubectl get pods -n longhorn-system

# Volumes criados
kubectl get volumes.longhorn.io -n longhorn-system
```

## 🌐 **Interface Web**

```bash
# Expor interface temporariamente
make longhorn-ui

# Acesse: http://localhost:8080
```

**Funcionalidades da UI:**
- 📊 Dashboard com métricas
- 💾 Gestão de volumes
- 📸 Snapshots e backups
- 🔧 Configuração de nós
- 📈 Monitoramento de performance

## 📝 **Exemplos de Uso**

### **1. Banco de Dados MySQL**

```yaml
# mysql-example.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "senha123"
        - name: MYSQL_DATABASE
          value: "production"
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pv-claim
---
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
  - port: 3306
  selector:
    app: mysql
```

**Deploy:**
```bash
kubectl apply -f mysql-example.yaml

# Verificar
kubectl get pvc mysql-pv-claim
kubectl get pods -l app=mysql
kubectl logs -l app=mysql
```

### **2. Aplicação Web com Upload**

```yaml
# webapp-with-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: webapp-uploads
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: uploads
          mountPath: /usr/share/nginx/html/uploads
        - name: config
          mountPath: /etc/nginx/conf.d
      volumes:
      - name: uploads
        persistentVolumeClaim:
          claimName: webapp-uploads
      - name: config
        configMap:
          name: nginx-config
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  default.conf: |
    server {
        listen 80;
        server_name localhost;
        
        location / {
            root /usr/share/nginx/html;
            index index.html;
        }
        
        location /uploads {
            autoindex on;
            alias /usr/share/nginx/html/uploads;
        }
        
        client_max_body_size 100M;
    }
---
apiVersion: v1
kind: Service
metadata:
  name: webapp
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 30080
  selector:
    app: webapp
```

### **3. Storage Compartilhado (ReadWriteMany)**

```yaml
# shared-storage.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-data
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 2Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: log-aggregator
spec:
  replicas: 3
  selector:
    matchLabels:
      app: log-aggregator
  template:
    metadata:
      labels:
        app: log-aggregator
    spec:
      containers:
      - name: logger
        image: alpine:latest
        command: ["/bin/sh", "-c"]
        args:
        - |
          while true; do
            echo "$(date) - Pod $(hostname) - Log entry" >> /shared/application.log
            sleep 5
          done
        volumeMounts:
        - name: shared-storage
          mountPath: /shared
      volumes:
      - name: shared-storage
        persistentVolumeClaim:
          claimName: shared-data
```

## 🔧 **Comandos Úteis**

### **Gerenciamento de PVCs**
```bash
# Listar todos os PVCs
kubectl get pvc --all-namespaces

# Detalhes de um PVC
kubectl describe pvc <nome-pvc>

# Status de binding
kubectl get pvc -o wide

# Eventos relacionados
kubectl get events --field-selector involvedObject.kind=PersistentVolumeClaim
```

### **Monitoramento de Volumes**
```bash
# Volumes do Longhorn
kubectl get volumes.longhorn.io -n longhorn-system

# Engines (processo de volume)
kubectl get engines.longhorn.io -n longhorn-system

# Replicas (cópias dos dados)
kubectl get replicas.longhorn.io -n longhorn-system

# Nós do Longhorn
kubectl get nodes.longhorn.io -n longhorn-system
```

### **Troubleshooting**
```bash
# Logs do Longhorn Manager
kubectl logs -n longhorn-system deployment/longhorn-manager

# Status detalhado
make longhorn-status

# Verificar nós prontos
kubectl get nodes.longhorn.io -n longhorn-system -o wide

# Eventos do namespace
kubectl get events -n longhorn-system
```

## 📸 **Snapshots e Backups**

### **Criar Snapshot Via UI**
1. Acesse: `make longhorn-ui`
2. Navegue: **Volume** → Selecionar volume → **Take Snapshot**
3. Configure: Nome e labels do snapshot

### **Criar Snapshot Via YAML**
```yaml
# snapshot-example.yaml
apiVersion: longhorn.io/v1beta1
kind: Snapshot
metadata:
  name: mysql-backup-daily
  namespace: longhorn-system
spec:
  volume: pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  snapshotName: mysql-$(date +%Y%m%d-%H%M)
```

### **Backup para S3 (Opcional)**
```yaml
# backup-target.yaml
apiVersion: v1
kind: Secret
metadata:
  name: s3-secret
  namespace: longhorn-system
type: Opaque
data:
  AWS_ACCESS_KEY_ID: <base64-encoded-key>
  AWS_SECRET_ACCESS_KEY: <base64-encoded-secret>
  AWS_ENDPOINTS: <base64-encoded-endpoint>
```

## ⚡ **Scripts de Automação**

### **Backup Automático**
```bash
# scripts/backup-volumes.sh
#!/bin/bash

VOLUMES=$(kubectl get pvc -o jsonpath='{.items[*].spec.volumeName}')

for volume in $VOLUMES; do
    echo "Criando snapshot para volume: $volume"
    kubectl apply -f - <<EOF
apiVersion: longhorn.io/v1beta1
kind: Snapshot
metadata:
  name: auto-backup-$(date +%Y%m%d-%H%M)-${volume}
  namespace: longhorn-system
spec:
  volume: $volume
EOF
done
```

### **Monitoramento de Espaço**
```bash
# scripts/monitor-storage.sh
#!/bin/bash

echo "📊 Relatório de Storage Longhorn"
echo "================================"

# Total de volumes
TOTAL_VOLUMES=$(kubectl get volumes.longhorn.io -n longhorn-system --no-headers | wc -l)
echo "📦 Total de volumes: $TOTAL_VOLUMES"

# Espaço usado
kubectl get volumes.longhorn.io -n longhorn-system -o custom-columns="NAME:.metadata.name,SIZE:.spec.size,STATE:.status.state"

# Storage disponível nos nós
echo "💾 Espaço disponível nos nós:"
kubectl get nodes.longhorn.io -n longhorn-system -o custom-columns="NODE:.metadata.name,MAX_STORAGE:.spec.disks.*.storageMaximum"
```

## 🔒 **Configurações de Segurança**

### **Backup Encryption**
```yaml
# encryption-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: longhorn-crypto
  namespace: longhorn-system
type: Opaque
stringData:
  CRYPTO_KEY_VALUE: "sua-chave-de-32-caracteres-aqui"
  CRYPTO_KEY_PROVIDER: "secret"
  CRYPTO_KEY_CIPHER: "aes-256-cbc"
```

### **Access Control**
```yaml
# rbac-storage.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-admin
rules:
- apiGroups: [""]
  resources: ["persistentvolumes", "persistentvolumeclaims"]
  verbs: ["*"]
- apiGroups: ["longhorn.io"]
  resources: ["*"]
  verbs: ["*"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: storage-admin-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: storage-admin
subjects:
- kind: User
  name: storage-admin
  apiGroup: rbac.authorization.k8s.io
```

## 📚 **Recursos Adicionais**

- **Documentação Oficial**: https://longhorn.io/docs/
- **Troubleshooting**: https://longhorn.io/docs/1.5.3/troubleshooting/
- **Best Practices**: https://longhorn.io/docs/1.5.3/best-practices/
- **GitHub Issues**: https://github.com/longhorn/longhorn/issues

## 🎯 **Próximos Passos**

1. **Instale o Longhorn**: `make install-longhorn`
2. **Teste básico**: `make test-longhorn`
3. **Explore a UI**: `make longhorn-ui`
4. **Deploy uma aplicação** com volume persistente
5. **Configure backups** automáticos
6. **Monitore performance** via interface web

---

*📅 Última atualização: 15 de Agosto de 2025*
