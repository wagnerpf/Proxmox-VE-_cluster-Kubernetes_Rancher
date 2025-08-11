[masters]
%{ for master in masters ~}
${master.name} ansible_host=${master.ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=~/.ssh/k8s-cluster-key
%{ endfor ~}

[workers]
%{ for worker in workers ~}
${worker.name} ansible_host=${worker.ip} ansible_user=${ssh_user} ansible_ssh_private_key_file=~/.ssh/k8s-cluster-key
%{ endfor ~}

[k8s_cluster:children]
masters
workers

[all:vars]
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
ansible_python_interpreter=/usr/bin/python3
