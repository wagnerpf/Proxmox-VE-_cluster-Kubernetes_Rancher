#!/bin/bash

# Script para obter o comando de join do master

set -e

# Ler parâmetros JSON do stdin
eval "$(jq -r '@sh "MASTER_IP=\(.master_ip) SSH_USER=\(.ssh_user) SSH_KEY=\(.ssh_key)"')"

# Obter comando de join do master via SSH
JOIN_COMMAND=$(ssh -o StrictHostKeyChecking=no -i "${SSH_KEY}" "${SSH_USER}@${MASTER_IP}" "cat /home/ubuntu/join-command.txt" 2>/dev/null || echo "")

# Retornar JSON com o comando
jq -n --arg join_command "$JOIN_COMMAND" '{"join_command":$join_command}'
