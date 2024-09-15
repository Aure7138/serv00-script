#!/bin/bash

# 设置变量
# UDP_PORT=8080
PASSWORD=$(openssl rand -base64 12)

# 创建目录并进入
cd $HOME
mkdir -p hysteria2 && cd hysteria2 > /dev/null 2>&1

# 下载 Hysteria
curl -s -L -O https://github.com/apernet/hysteria/releases/latest/download/hysteria-freebsd-amd64 > /dev/null 2>&1
chmod +x hysteria-freebsd-amd64

# 生成证书
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout server.key -out server.crt -subj "/CN=bing.com" -days 36500 > /dev/null 2>&1

# 创建配置文件
cat <<EOF > config.yaml
listen: :$UDP_PORT

tls:
  cert: $HOME/hysteria2/server.crt
  key: $HOME/hysteria2/server.key

auth:
  type: password
  password: $PASSWORD
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

# 启动 Hysteria
nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 &

echo "Hysteria 配置信息"
echo "UDP端口: $UDP_PORT"
echo "密码: $PASSWORD"
