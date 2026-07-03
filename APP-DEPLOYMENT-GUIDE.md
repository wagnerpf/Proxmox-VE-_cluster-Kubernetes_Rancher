# 🚀 Manual de Deploy de Aplicações no Cluster

> **Como levar qualquer aplicação (Zabbix, apps internas, etc.) do zero até rodando neste cluster específico** — cobre o passo a passo genérico e as particularidades deste ambiente hardened (Pod Security Standards, Longhorn, UFW, NetworkPolicy).

Este manual assume que o cluster já existe (`terraform apply` já rodou com sucesso). Ele **não** cobre provisionamento de infraestrutura — isso está no [README.md](README.md) e [CLUSTER-QUICK-GUIDE.md](CLUSTER-QUICK-GUIDE.md).

**Tudo aqui é feito via Ansible, seguindo o mesmo padrão de `ansible/longhorn-install.yml`.** Não é necessário instalar `kubectl` nem `helm` na sua máquina, nem copiar o `kubeconfig` para local — os módulos `kubernetes.core.k8s`/`kubernetes.core.helm` rodam **dentro do cluster, no master**, usando o kubeconfig que a role `kubernetes-master` já deixou em `/home/{{ ansible_user }}/.kube/config`. O único pré-requisito na máquina de operação é o mesmo que já existe hoje para o resto do projeto: Ansible + a collection `kubernetes.core` instalados localmente (quem executa o `ansible-playbook`), e acesso SSH ao inventory.

---

## ✅ Pré-requisitos

- [ ] `ansible` e a collection `kubernetes.core` instalados na máquina que roda o `ansible-playbook` (mesma coisa já usada para `site.yml`/`longhorn-install.yml`)
- [ ] `ansible/inventory` já gerado pelo Terraform e o cluster no ar
- [ ] Nenhum requisito de `kubectl`/`helm`/kubeconfig local — isso tudo acontece no master

---

## 📋 Passo a passo genérico

### 1. Criar um playbook dedicado à aplicação
Siga o mesmo molde de `ansible/longhorn-install.yml`: um playbook por aplicação, rodando só no primeiro master.

```yaml
# ansible/minha-app-install.yml
---
- name: Instalar Minha App
  hosts: masters[0]
  gather_facts: false

  pre_tasks:
    - name: "Instalar dependência Python para os módulos kubernetes.core"
      apt:
        name: python3-kubernetes
        state: present
        update_cache: yes
      become: yes
```

### 2. Se for instalar via Helm chart, garanta o binário `helm` no master (não local)
```yaml
    - name: "Verificar se helm já está instalado"
      command: helm version --short
      register: helm_check
      changed_when: false
      failed_when: false

    - name: "Instalar helm no master"
      shell: |
        curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
      become: yes
      when: helm_check.rc != 0
```

### 3. Criar o namespace e decidir o Pod Security Standard
O namespace `default` deste cluster já vem rotulado como:
```
pod-security.kubernetes.io/enforce=baseline
pod-security.kubernetes.io/audit=restricted
pod-security.kubernetes.io/warn=restricted
```
Namespaces novos **não herdam isso automaticamente** — nascem sem rótulo (equivalente a `privileged`/sem restrição). Decida explicitamente, dentro do próprio playbook:

```yaml
  tasks:
    - name: "Criar namespace da aplicação"
      kubernetes.core.k8s:
        state: present
        api_version: v1
        kind: Namespace
        name: minha-app
        definition:
          metadata:
            labels:
              # app comum: replica o padrão do default. Se precisar de
              # hostNetwork/hostPID/capabilities extras (ex.: agente tipo
              # Zabbix agent), use "privileged" aqui em vez de "baseline",
              # como o role longhorn faz para longhorn-system.
              pod-security.kubernetes.io/enforce: baseline
              pod-security.kubernetes.io/audit: restricted
              pod-security.kubernetes.io/warn: restricted
```

### 4. Provisionar storage, se a app precisar de dados persistentes
O cluster já tem **Longhorn** como StorageClass padrão. Antes de aplicar o PVC, confira quantos workers estão disponíveis para storage:
```yaml
    - name: "Verificar nós disponíveis para storage"
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Node
      register: cluster_nodes
```
- O `numberOfReplicas` padrão do Longhorn é **3**. Se o cluster tiver menos de 3 workers schedulable (o master normalmente tem taint `control-plane:NoSchedule` e não conta), os volumes ficam `degraded`. Ajuste `numberOfReplicas` no `definition:` do PVC/StorageClass para bater com o número real de workers, ou aumente `worker_count` no Terraform.
- Aponte `storageClassName: longhorn` nos PVCs.

### 5. Aplicar os manifests da aplicação
Via `kubernetes.core.k8s` com `definition:` inline (mesma técnica usada no role `longhorn`), ou baixando um manifest remoto com `uri` + `from_yaml_all`, ou via `kubernetes.core.helm` se for um chart:

```yaml
    - name: "Aplicar manifests da aplicação"
      kubernetes.core.k8s:
        state: present
        definition: "{{ lookup('file', 'files/minha-app.yaml') | from_yaml_all | list }}"
        wait: true

    # ou, para Helm:
    - name: "Instalar via Helm"
      kubernetes.core.helm:
        name: minha-app
        chart_ref: minha-app/minha-app
        release_namespace: minha-app
        create_namespace: false
        values:
          persistence:
            storageClass: longhorn
```

### 6. Expor a aplicação
Este cluster **não tem Ingress Controller instalado por padrão**. Duas opções:
- **NodePort** — mais simples, já funciona sem nada extra: a faixa `30000:32767` já está liberada no UFW dos workers.
- **Ingress** — se preferir domínio/TLS, precisa instalar um `ingress-nginx` (mesmo padrão Ansible acima) e **abrir 80/443 manualmente no UFW** dos nodes que vão rodar o controller (adicione uma task `community.general.ufw` — não é automático em nenhum role hoje).

Se a app precisar receber conexões de fora do cluster numa porta específica (ex.: um trapper como o `10051` do Zabbix server), adicione a regra no UFW do node relevante com uma task `community.general.ufw`, dentro do próprio playbook ou num role.

### 7. Validar no final do playbook (post_tasks)
```yaml
  post_tasks:
    - name: "Verificar pods em execução"
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: minha-app
        field_selectors:
          - status.phase=Running
      register: app_running_pods

    - name: "Relatório final"
      debug:
        msg:
          - "✅ Deploy concluído! Pods rodando: {{ app_running_pods.resources | length }}"
```

### 8. Executar
```bash
cd ansible && ansible-playbook -i inventory minha-app-install.yml && cd ..
```

---

## ⚠️ Particularidades deste cluster (checklist antes de subir algo novo)

| Item | Situação neste cluster | O que fazer |
|---|---|---|
| **Pod Security Standard** | `default` = baseline/restricted; namespaces novos nascem sem rótulo | Rotule o namespace explicitamente via `kubernetes.core.k8s` no próprio playbook (passo 3) |
| **NetworkPolicy** | Canal/Calico faz enforcement real (não é Flannel puro) | Hoje não há default-deny; se você mesmo adicionar uma NetworkPolicy, cuidado com `namespaceSelector`-only em apps com admission webhook (mesma pegadinha documentada para o Longhorn) |
| **Storage** | Longhorn default, réplica padrão = 3 | Confirme `numberOfReplicas` compatível com o nº de workers schedulable |
| **Taint do master** | Não é removido em nenhum lugar do repo | Workloads normais (incluindo replicas do Longhorn) não são agendados no master |
| **Ingress** | Não instalado por padrão | NodePort funciona de cara; Ingress exige instalar o controller via Ansible + abrir 80/443 no UFW |
| **HA de control-plane** | `groups['masters'][0]` é hardcoded no role `kubernetes-worker` | Não há multi-master real; não assuma failover do control-plane |
| **Firewall (UFW)** | Só as portas listadas em `ansible/roles/common` e `kubernetes-master`/`kubernetes-worker` estão abertas | Qualquer porta nova (trapper, webhook externo, etc.) precisa de uma task `community.general.ufw` no playbook da app |
| **kubectl/helm local** | Não são necessários | Toda execução é `ansible-playbook` a partir do inventory; os módulos rodam no master |

---

## 🔍 Troubleshooting comum

**Pod não sobe, evento tipo `violates PodSecurity ... baseline`**
→ O namespace está com PSS `baseline`/`restricted` e o pod pede algo privilegiado (hostPath, hostNetwork, capability). Ou ajuste a app para não precisar disso, ou rotule o namespace como `privileged` no passo 3.

**PVC fica `Pending` ou volume aparece `degraded` no Longhorn**
→ Réplicas pedidas (padrão 3) maior que o nº de nodes schedulable disponíveis para storage. Reduza `numberOfReplicas` no `definition:` ou adicione workers.

**Não consigo acessar a app pelo NodePort de fora**
→ Confirme que a porta escolhida está dentro de `30000:32767` (única faixa liberada no UFW por padrão) e que está testando o IP de um **worker**, não do master.

**App precisa falar com algo fora do cluster numa porta específica e não conecta**
→ Porta não está no UFW. Adicione uma task `community.general.ufw` no node correto.

**Pods em `Pending` por falta de recurso**
→ Verifique via `kubernetes.core.k8s_info` (kind: Node) — com 1 master (tainted) + N workers, a capacidade real de agendamento é só dos workers. Ajuste requests/limits ou o `worker_count`/`worker_memory`/`worker_cpu` no Terraform.

**`kubernetes.core.k8s` falha com erro de conexão/autenticação**
→ Confirme que o playbook está com `hosts: masters[0]` e que não está usando `become: yes` nas tasks que chamam a API (o kubeconfig fica em `/home/{{ ansible_user }}/.kube/config`, do usuário SSH, não do root).

---

## 📎 Exemplo mínimo completo (nginx via NodePort, 100% Ansible)

```yaml
# ansible/demo-nginx-install.yml
---
- name: Deploy demo nginx
  hosts: masters[0]
  gather_facts: false

  pre_tasks:
    - name: "Instalar dependência Python para os módulos kubernetes.core"
      apt:
        name: python3-kubernetes
        state: present
        update_cache: yes
      become: yes

  tasks:
    - name: "Criar namespace"
      kubernetes.core.k8s:
        state: present
        api_version: v1
        kind: Namespace
        name: demo-nginx
        definition:
          metadata:
            labels:
              pod-security.kubernetes.io/enforce: baseline
              pod-security.kubernetes.io/audit: restricted
              pod-security.kubernetes.io/warn: restricted

    - name: "Criar deployment"
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: nginx
            namespace: demo-nginx
          spec:
            replicas: 2
            selector:
              matchLabels: { app: nginx }
            template:
              metadata:
                labels: { app: nginx }
              spec:
                containers:
                  - name: nginx
                    image: nginx:1.27-alpine
                    ports:
                      - containerPort: 80
                    resources:
                      requests: { cpu: "50m", memory: "64Mi" }
                      limits: { cpu: "200m", memory: "128Mi" }

    - name: "Criar service NodePort"
      kubernetes.core.k8s:
        state: present
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: nginx
            namespace: demo-nginx
          spec:
            type: NodePort
            selector: { app: nginx }
            ports:
              - port: 80
                nodePort: 30080

  post_tasks:
    - name: "Verificar pods em execução"
      kubernetes.core.k8s_info:
        api_version: v1
        kind: Pod
        namespace: demo-nginx
        field_selectors:
          - status.phase=Running
      register: nginx_pods

    - name: "Relatório final"
      debug:
        msg: "✅ nginx rodando com {{ nginx_pods.resources | length }} pods. Teste: curl http://<IP-de-qualquer-worker>:30080"
```

```bash
cd ansible && ansible-playbook -i inventory demo-nginx-install.yml && cd ..
curl http://<IP-de-qualquer-worker>:30080
```
