BASTION
=========

SetUp
-----

```
cp .env.sample .env
```
```
docker-compose --compatibility  up -d --build
```

Vault Integration
-------------------

Enable SSH
```
vault secrets enable -path=bastion ssh
```

Generate private CA
```
vault write bastion/config/ca generate_signing_key=true
```

Create Bastion Role
```
vault write bastion/roles/bastion -<<"EOH"
{
  "allow_user_certificates": true,
  "allowed_users": "bastion",
  "default_extensions": [
    {
      "permit-pty": "",
      "permit-port-forwarding": "",
    }
  ],
  "key_type": "ca",
  "default_user": "bastion",
  "ttl": "30m0s",
  "allow_user_key_ids": "false",
  "key_id_format": "{{token_display_name}}"
}
EOH
```

List Roles
```
vault list bastion/roles
```

Add Policy

```
vault policy write bastion-ssh -<<EOF 

  path "bastion/sign/bastion" {
    capabilities = ["create", "update"]
  }

  path "bastion/config/ca" {
    capabilities = ["read"]
  }

EOF
```

Add created policy and change `user_claim` attribute to show the name of the user.

```
vault write auth/keycloak/role/manager \
        bound_audiences="vault" \                                              
        allowed_redirect_uris="https://vault.example.com/ui/vault/auth/keycloak/oidc/callback,https://vault.example.com/keycloak/callback,http://localhost:8250/oidc/callback" \
        user_claim="preferred_username" \                                         
        policies="manager,bastion-ssh" \
        ttl=1h \   
        role_type="oidc" \
        oidc_scopes="openid"
```

Configure Client to access through bastion

```
vim ~/.ssh/config
```
```
Host bastion
        Hostname bastion.example.com
        Port 222
        User bastion
        IdentityFile ~/.ssh/id_rsa.pub
        CertificateFile ~/.ssh/signed-cert.pub
        ProxyCommand none
        PasswordAuthentication no
        ForwardAgent no

Host *.example.com
        User bastion
        IdentityFile ~/.ssh/id_rsa.pub
        CertificateFile ~/.ssh/signed-cert.pub
        ProxyJump bastion
        ForwardAgent no
```

### SSH Client

```
#!/bin/bash

PUBLIC_KEY=$HOME/.ssh/id_rsa.pub
PRIVATE_KEY=$HOME/.ssh/id_rsa
SSH_CERTIFICATE=$HOME/.ssh/signed-cert.pub
VAULT_PATH=bastion
VAULT_ROLE=bastion

export VAULT_ADDR=https://vault.example.com

if ! vault token lookup > /dev/null 2>&1; then
 vault login -method=oidc -path=keycloak -no-print
fi

vault write -field=signed_key ${VAULT_PATH}/sign/${VAULT_ROLE} public_key=@${PUBLIC_KEY} > ${SSH_CERTIFICATE}

ssh-add -k > /dev/null 2>&1

ssh -J $1 -i ${PRIVATE_KEY} -i ${SSH_CERTIFICATE} ${VAULT_ROLE}@$2 -p${3:-22}

```

Run

```
script bastion_name host
```


FAIL2BAN
---------

### Useful Commands

Status
```
docker exec -it fail2ban fail2ban-client status sshd
```
Manually Block IP
```
docker exec -it fail2ban fail2ban-client set sshd banip <IP>
```
Manually Unblock IP
```
docker exec -it fail2ban fail2ban-client set sshd unbanip <IP>
```

### Troubleshooting

Debian 10 use iptabes-nft. This is incompatible with docker.
```
sudo update-alternatives --config iptables
```
There are 2 choices for the alternative iptables (providing /usr/sbin/iptables).

```
  Selection    Path                       Priority   Status
------------------------------------------------------------
* 0            /usr/sbin/iptables-nft      20        auto mode
  1            /usr/sbin/iptables-legacy   10        manual mode
  2            /usr/sbin/iptables-nft      20        manual mode

Press <enter> to keep the current choice[*], or type selection number:
```

And then restart Docker
```
systemctl restart docker
```

### Manually unban IP from iptables

```
sudo iptables -L f2b-sshd --line-numbers
```
```
Chain f2b-sshd (3 references)
num  target     prot opt source               destination         
1    REJECT     all  --  188.127.186.153      anywhere             reject-with icmp-port-unreachable
2    RETURN     all  --  anywhere             anywhere            
3    RETURN     all  --  anywhere             anywhere            
4    RETURN     all  --  anywhere             anywhere 
```
```
sudo iptables -D f2b-sshd 1
```

TODO
======

SSH-SERVER
-----------

### Client

* Add options
* Create contexts

### Session record

* Record jump sessions
* Add certificate ID insteat of username

### Links:

* https://engineering.fb.com/production-engineering/scalable-and-secure-access-with-ssh/
* https://dickingwithdocker.com/2020/05/securing-ssh-with-the-vault-ssh-backend-and-github-authentication/
* https://github.com/uber/pam-ussh
