#!/bin/bash

set -e

## FAIL2BAN CONFIG ##
echo "------Configure Fail2ban------"
sed -i 's/FAIL2BAN_LOGLEVEL/'"${FAIL2BAN_LOGLEVEL:-INFO}"'/g' /etc/fail2ban/fail2ban.d/default.conf
sed -i 's/SSH_PORT/'"${SSH_PORT:-222}"'/g' /etc/fail2ban/jail.d/ssh.conf
sed -i 's/FAIL2BAN_SSH_MAXRETRY/'"${FAIL2BAN_SSH_MAXRETRY:-3}"'/g' /etc/fail2ban/jail.d/ssh.conf
sed -i 's/FAIL2BAN_SSH_BANTIME/'"${FAIL2BAN_SSH_BANTIME:-86400}"'/g' /etc/fail2ban/jail.d/ssh.conf

echo "------Start Fail2ban------"
fail2ban-server -f -x -v start
status=$?
if [ $status -ne 0 ]; then
  echo "Failed to start fail2ban: $status"
  exit $status
fi
