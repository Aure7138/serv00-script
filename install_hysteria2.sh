#!/bin/bash

# 安装 Hysteria2
install_hysteria2() {
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
    echo 服务器 IP: $(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
}

# 卸载 Hysteria2
uninstall_hysteria2() {
    pkill -f "./hysteria-freebsd-amd64 server -c config.yaml" > /dev/null 2>&1
    rm -rf $HOME/hysteria2 > /dev/null 2>&1
    echo "Hysteria2 已成功卸载"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo "请选择操作："
        echo "1. 安装 Hysteria2"
        echo "2. 卸载 Hysteria2"
        read -p "输入选项 (1 或 2): " choice
    else
        choice=$1
    fi

    case $choice in
        1)
            install_hysteria2
            ;;
        2)
            uninstall_hysteria2
            ;;
        *)
            echo "无效的选项，请输入 1 或 2"
            ;;
    esac
}

# 执行主函数
main "$@"
