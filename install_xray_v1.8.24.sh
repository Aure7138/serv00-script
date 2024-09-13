#!/bin/bash

# 设置变量
# SOCKS_PORT=1080
# VMESS_PORT=8080
# SOCKS_USER="vtk"
# SOCKS_PASS="123456"

# 创建目录并进入
mkdir -p xray && cd xray > /dev/null 2>&1

# 下载并解压Xray
curl -s -L -O https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-freebsd-64.zip > /dev/null 2>&1
unzip -q Xray-freebsd-64.zip
chmod +x xray

# 生成UUID
uuid=$(./xray uuid)

# 创建配置文件
cat <<EOF > config.json
{
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $SOCKS_PORT,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "$SOCKS_USER",
            "pass": "$SOCKS_PASS"
          }
        ]
      }
    },
    {
      "listen": "0.0.0.0",
      "port": $VMESS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "$uuid"
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "none"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# 启动Xray
nohup ./xray run -config config.json > /dev/null 2>&1 &

echo "SOCKS5端口: $SOCKS_PORT"
echo "SOCKS5用户名: $SOCKS_USER"
echo "SOCKS5密码: $SOCKS_PASS"
echo "VMess端口: $VMESS_PORT"
echo "VMess UUID: $uuid"