FROM alpine:3.10

LABEL mantainer "Ismael Chasco"

RUN set -ex \
    && apk add --update --no-cache \
    bash \
    curl \
    supervisor \
    rsyslog \
    util-linux \
    openssh-server-common \
    openssh-keygen \
    openssh-client \
    openssh-server-pam \
    openssh-server \
    tzdata \
    && echo "GENERATING MODULI..." \
    && ssh-keygen -G moduli-2048.candidates -b 2048 \
    && ssh-keygen -T /etc/ssh/moduli -f moduli-2048.candidates \
    && mkdir /var/log/ssh/ \
    && echo "HostKey /etc/ssh/ssh_host_ed25519_key" >> /etc/ssh/sshd_config \
    && echo "HostKey /etc/ssh/ssh_host_rsa_key" >> /etc/ssh/sshd_config \
    && echo "HostKey /etc/ssh/ssh_host_ecdsa_key" >> /etc/ssh/sshd_config \
    && /usr/bin/ssh-keygen -A \
    && rm -rf /var/cache/apk/* /tmp/* 

COPY entrypoint.sh /usr/local/bin/
COPY bastion-shell /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/bastion-shell
COPY config/supervisor/supervisord.conf /etc/supervisord.conf
COPY config/rsyslog/rsyslogd.conf /etc/rsyslogd.conf
COPY config/ssh/* /etc/ssh/
COPY config/ssh/issue.net /etc/motd

EXPOSE 222

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
