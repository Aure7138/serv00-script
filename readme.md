# FreeBSD amd64

## 安装 Xray

```bash
SOCKS_PORT=TCP端口 VMESS_PORT=TCP端口 bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_xray_v1.8.24.sh)
```

## 卸载 Xray

```bash
pkill -f "./xray run -c config.json" > /dev/null 2>&1
rm -rf ~/xray > /dev/null 2>&1
```

## 安装 Hysteria2

```bash
UDP_PORT=UDP端口 bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/install_hysteria2.sh)
```

## 卸载 Hysteria2

```bash
pkill -f "./hysteria-freebsd-amd64 server -c config.yaml" > /dev/null 2>&1
rm -rf ~/hysteria > /dev/null 2>&1
```

## 添加定时任务

```bash
bash <(curl -L -s https://raw.githubusercontent.com/Aure7138/serv00-script/main/crontab_monitor.sh)
```

## Actions Repository Secrets

### ACCOUNTS_JSON

```json
[
  {"username": "username", "password": "password", "panel": "panel10.serv00.com", "ssh": "s10.serv00.com"},
  {"username": "username", "password": "password", "panel": "panel11.serv00.com", "ssh": "s11.serv00.com"},
  {"username": "username", "password": "password", "panel": "panel.ct8.pl", "ssh": "s1.ct8.pl"}
]
```
