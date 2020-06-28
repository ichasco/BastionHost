FROM alpine:3.10

LABEL mantainer="Ismael Chasco"

ENV FAIL2BAN_VERSION="0.11" 

RUN set -ex \
    && apk --update --no-cache add \
    bash \
    curl \
    ipset \
    iptables \
    ip6tables \
    kmod \
    python3 \
    python3-dev \
    py3-setuptools \
    ssmtp \
    tzdata \
    wget \
    whois \
    && pip3 install --upgrade pip \
    && pip3 install dnspython3 pyinotify \
    && cd /tmp \
    && curl -SsOL https://github.com/fail2ban/fail2ban/archive/${FAIL2BAN_VERSION}.zip \
    && unzip ${FAIL2BAN_VERSION}.zip \
    && cd fail2ban-${FAIL2BAN_VERSION} \
    && 2to3 -w --no-diffs bin/* fail2ban \
    && python3 setup.py install \
    && rm -rf /etc/fail2ban/jail.d /var/cache/apk/* /tmp/*

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
COPY config/fail2ban.d/ /etc/fail2ban/fail2ban.d/
COPY config/jail.d/ /etc/fail2ban/jail.d/

VOLUME /var/lib/fail2ban

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

HEALTHCHECK --interval=10s --timeout=5s \
CMD fail2ban-client ping || exit 1
