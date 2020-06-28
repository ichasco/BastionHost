#!/bin/bash

set -e

## CREATE USER ##
echo "------Create User------"
id -u ${USER:-bastion} &>/dev/null || adduser -D --home /home/${USER:-bastion} --shell /bin/bash ${USER:-bastion}

## RECORD SESSION ##
if [[ ${SSH_RECORD_SESSION} == "true" ]]; then
  echo "------Enable Session Recording------"
  echo -e "\nForceCommand /usr/local/bin/bastion-shell" >> /etc/ssh/sshd_config
  mkdir -p /var/log/bastion
  chown ${USER:-bastion}:${USER:-bastion} /var/log/bastion
  chmod -R 770 /var/log/bastion
fi

## SSH CONFIGURATION ##
echo "------Configure SSH------"
sed -i 's/SSH_PORT/'"${SSH_PORT:-222}"'/g' /etc/ssh/sshd_config
sed -i 's/SSH_USER/'"${SSH_USER:-bastion}"'/g' /etc/ssh/sshd_config
sed -i 's/SSH_CLIENT_ALIVE_INTERVAL/'"${SSH_CLIENT_ALIVE_INTERVAL:-300}"'/g' /etc/ssh/sshd_config
sed -i 's/SSH_CLIENT_ALIVE_COUNT_MAX/'"${SSH_CLIENT_ALIVE_COUNT_MAX:-2}"'/g' /etc/ssh/sshd_config
sed -i 's/SSH_MAX_AUTH_TRIES/'"${SSH_MAX_AUTH_TRIES:-3}"'/g' /etc/ssh/sshd_config

if [[ ${VAULT_ENABLE} == "true" ]]; then
  echo "------Add Vault Public CA------"
  curl -s -o /etc/ssh/vault.pem https://${VAULT_HOST}/v1/${VAULT_SSH_PATH}/public_key
  echo -e "\nTrustedUserCAKeys /etc/ssh/vault.pem" >> /etc/ssh/sshd_config
fi
/usr/sbin/sshd -t
touch /var/log/ssh/auth.log
tail -f /var/log/ssh/auth.log &

echo "------Start Supervisord------"
/usr/bin/supervisord
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start supervisord: $status"
  exit $status
fi

