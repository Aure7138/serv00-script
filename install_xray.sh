#!/bin/bash

echo "欢迎使用Xray一键安装脚本"

# 创建目录并进入
mkdir -p xray && cd xray

# 下载并解压Xray
echo "正在下载Xray..."
curl -L -O https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-freebsd-64.zip
unzip Xray-freebsd-64.zip
chmod +x xray

# 设置端口
read -p "请输入SOCKS5端口 (默认为1080): " socks_port
socks_port=${socks_port:-1080}

read -p "请输入VMess端口 (默认为8080): " vmess_port
vmess_port=${vmess_port:-8080}

# 设置用户名和密码
read -p "请输入SOCKS5用户名 (默认为vtk): " socks_user
socks_user=${socks_user:-vtk}

read -p "请输入SOCKS5密码 (默认为123456): " socks_pass
socks_pass=${socks_pass:-123456}

# 生成UUID
uuid=$(./xray uuid)

# 创建配置文件
cat <<EOF > config.json
{
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $socks_port,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "$socks_user",
            "pass": "$socks_pass"
          }
        ]
      }
    },
    {
      "listen": "0.0.0.0",
      "port": $vmess_port,
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
echo "正在启动Xray..."
nohup ./xray run -config config.json > /dev/null 2>&1 &

echo "Xray已成功安装并启动"
echo "SOCKS5端口: $socks_port"
echo "SOCKS5用户名: $socks_user"
echo "SOCKS5密码: $socks_pass"
echo "VMess端口: $vmess_port"
echo "VMess UUID: $uuid"