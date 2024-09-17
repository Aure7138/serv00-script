# FreeBSD amd64 通用

## 安装 Xray
```bash
TCP_PORT_1=TCP端口 TCP_PORT_2=TCP端口 bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_xray_v1.8.24.sh) 1 3
```

## 卸载 Xray

```bash
bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_xray_v1.8.24.sh) 2 4
```

## 安装 Hysteria2

```bash
UDP_PORT=UDP端口 bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_hysteria2.sh) 1 3
```

## 卸载 Hysteria2

```bash
bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_hysteria2.sh) 2 4
```

## 添加定时任务

```bash
bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/crontab_monitor.sh)
```

## 删除定时任务

```bash
crontab -r -f
```

## 输出服务器 IP

```bash
echo 服务器 IP: $(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
```

## 杀死所有进程

```bash
pkill -u $(whoami)
```

# Actions Repository Secrets

## ACCOUNTS_JSON

```json
[
  {"username": "username", "password": "password", "panel": "panel10.serv00.com", "ssh": "s10.serv00.com"},
  {"username": "username", "password": "password", "panel": "panel11.serv00.com", "ssh": "s11.serv00.com"},
  {"username": "username", "password": "password", "panel": "panel.ct8.pl", "ssh": "s1.ct8.pl"}
]
```

# Xray 配置

## SOCKS5

```base
local port="$1"
local path="$2"
local filename="$3"
local username=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 8 | head -n 1)
local password=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+' < /dev/urandom | fold -w 12 | head -n 1)
```

### InboundObject

```json
{
    "port": $port,
    "protocol": "socks",
    "settings": {
        "auth": "password",
        "accounts": [
            {
                "user": "$username",
                "pass": "$password"
            }
        ]
    }
}
```

### OutboundObject

```json
{
    "protocol": "socks",
    "settings": {
        "servers": [
            {
                "address": "$SERVER_IP",
                "port": $port,
                "users": [
                    {
                        "user": "$username",
                        "pass": "$password"
                    }
                ]
            }
        ]
    }
}
```

## VLESS+WS

```base
local port="$1"
local path="$2"
local filename="$3"
local uuid=$(./xray uuid)
```

### InboundObject

```json
{
    "port": $port,
    "protocol": "vless",
    "settings": {
        "clients": [
            {
                "id": "$uuid"
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "ws"
    }
}
```

### OutboundObject

```json
{
    "protocol": "vless",
    "settings": {
        "vnext": [
            {
                "address": "$SERVER_IP",
                "port": $port,
                "users": [
                    {
                        "id": "$uuid",
                        "encryption": "none"
                    }
                ]
            }
        ]
    },
    "streamSettings": {
        "network": "ws"
    }
}
```

## VMESS+WS

```base
local port="$1"
local path="$2"
local filename="$3"
local uuid=$(./xray uuid)
```

### InboundObject

```json
{
    "port": $port,
    "protocol": "vmess",
    "settings": {
        "clients": [
            {
                "id": "$uuid"
            }
        ]
    },
    "streamSettings": {
        "network": "ws"
    }
}
```

### OutboundObject

```json
{
    "protocol": "vmess",
    "settings": {
        "vnext": [
            {
                "address": "$SERVER_IP",
                "port": $port,
                "users": [
                    {
                        "id": "$uuid"
                    }
                ]
            }
        ]
    },
    "streamSettings": {
        "network": "ws"
    }
}
```

## VLESS+TCP+REALITY+VISION

```base
local port="$1"
local path="$2"
local filename="$3"
local uuid=$(./xray uuid)
local serverName="${uuid%%-*}.com"
local x25519_output=$(./xray x25519)
local privateKey=$(echo "$x25519_output" | grep "Private key:" | cut -d ' ' -f 3)
local publicKey=$(echo "$x25519_output" | grep "Public key:" | cut -d ' ' -f 3)
local shortId=$(openssl rand -hex $((RANDOM % 7 + 2)))
```

### InboundObject

```json
{
    "port": $port, 
    "protocol": "vless",
    "settings": {
        "clients": [
            {
                "id": "$uuid",
                "flow": "xtls-rprx-vision"
            }
        ],
        "decryption": "none"
    },
    "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
            "dest": "1.1.1.1:443",
            "serverNames": [
                "$serverName"
            ],
            "privateKey": "$privateKey",
            "shortIds": [
                "$shortId"
            ]
        }
    }
}
```

### OutboundObject

```json
{
    "protocol": "vless",
    "settings": {
        "vnext": [
            {
                "address": "$SERVER_IP", 
                "port": $port, 
                "users": [
                    {
                        "id": "$uuid",
                        "encryption": "none",
                        "flow": "xtls-rprx-vision"
                    }
                ]
            }
        ]
    },
    "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
            "fingerprint": "safari", 
            "serverName": "$serverName",
            "publicKey": "$publicKey",
            "shortId": "$shortId"
        }
    }
}
```
