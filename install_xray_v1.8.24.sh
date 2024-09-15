#!/bin/bash

# 函数：安装 Xray
install_xray() {
    # 设置变量
    # SOCKS_PORT=1080
    # VMESS_PORT=8080

    # 创建目录并进入
    cd $HOME
    mkdir -p xray && cd xray > /dev/null 2>&1

    # 下载并解压Xray
    curl -s -L -O https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-freebsd-64.zip > /dev/null 2>&1
    unzip -q Xray-freebsd-64.zip
    chmod +x xray

    # 生成UUID
    uuid=$(./xray uuid)

    # 生成随机的SOCKS5用户名和密码
    SOCKS_USER=$(openssl rand -base64 8)
    SOCKS_PASS=$(openssl rand -base64 12)

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

    # 执行 Xray 配置测试并捕获输出
    test_output=$(./xray run -c config.json -test 2>&1)
    echo "Xray 配置测试输出:"
    echo "$test_output"

    # 执行 Xray 并捕获输出
    output=$(./xray run -c config.json 2>&1 & sleep 1; pkill -f "./xray run -c config.json")
    echo "Xray 启动输出:"
    echo "$output"

    # 启动Xray
    nohup ./xray run -c config.json > /dev/null 2>&1 &
    
    # 输出 Xray 进程信息
    echo "Xray 进程信息:"
    ps aux | grep "[x]ray run -c config.json"

    echo "Xray 配置信息"
    echo "SOCKS5端口: $SOCKS_PORT"
    echo "SOCKS5用户名: $SOCKS_USER"
    echo "SOCKS5密码: $SOCKS_PASS"
    echo "VMess端口: $VMESS_PORT"
    echo "VMess UUID: $uuid"
    echo 服务器 IP: $(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
}

# 函数：卸载 Xray
uninstall_xray() {
    pkill -f "./xray run -c config.json" > /dev/null 2>&1
    rm -rf $HOME/xray > /dev/null 2>&1
    echo "Xray 已成功卸载"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo "请选择操作："
        echo "1. 安装 Xray"
        echo "2. 卸载 Xray"
        read -p "输入选项 (1 或 2): " choice
    else
        choice=$1
    fi

    case $choice in
        1)
            install_xray
            ;;
        2)
            uninstall_xray
            ;;
        *)
            echo "无效的选项，请输入 1 或 2"
            ;;
    esac
}

# 执行主函数
main "$@"