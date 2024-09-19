#!/bin/bash

# 检查系统是否为 FreeBSD amd64
if [ "$(uname)" != "FreeBSD" ] || [ "$(uname -m)" != "amd64" ]; then
    echo "此脚本仅支持 FreeBSD amd64 系统。"
    exit 1
fi

# 检查端口是否可用且可绑定
check_port() {
    local port=$1
    local protocol=$2

    # 验证协议输入
    if [ "$protocol" != "tcp" ] && [ "$protocol" != "udp" ]; then
        echo "无效的协议: $protocol"
        return 2
    fi

    # 验证端口是否为数字
    if ! [[ "$port" =~ ^[0-9]+$ ]]; then
        echo "无效的端口号: $port"
        return 2
    fi

    # 检查端口是否被占用
    if sockstat -4l | grep -q ":$port"; then
        echo "端口 $port ($protocol) 已被占用"
        return 1
    fi

    # 尝试绑定端口
    if [ "$protocol" = "tcp" ]; then
        nc -l $port >/dev/null 2>&1 &
    else
        nc -u -l $port >/dev/null 2>&1 &
    fi

    local pid=$!

    if kill -0 $pid 2>/dev/null; then
        kill $pid
        wait $pid 2>/dev/null
        echo "端口 $port ($protocol) 可用且可绑定"
        return 0
    else
        echo "端口 $port ($protocol) 不可绑定，可能没有权限"
        return 1
    fi
}

# 函数：生成 vless+ws 配置文件
generate_vless_ws_config() {
    local port="$1"
    local path="$2"
    local filename="$3"
    local uuid=$(./xray uuid)

    cat <<EOF > "$path/$filename"
{
  "inbounds": [
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
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

    echo "$uuid"
}

# 函数：生成 vless+tcp+reality 配置文件
generate_vless_tcp_reality_vision_config() {
    local port="$1"
    local path="$2"
    local filename="$3"
    local uuid=$(./xray uuid)
    
    # 获取uuid第一个-前的部分作为serverName
    local serverName="${uuid%%-*}.com"
    
    # 生成并保存 x25519 密钥对
    local x25519_output=$(./xray x25519)
    local privateKey=$(echo "$x25519_output" | grep "Private key:" | cut -d ' ' -f 3)
    local publicKey=$(echo "$x25519_output" | grep "Public key:" | cut -d ' ' -f 3)

    # 生成shortId
    local shortId=$(openssl rand -hex $((RANDOM % 7 + 2)))

    cat <<EOF > "$path/$filename"
{
  "inbounds": [
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
          "serverNames": ["$serverName"],
          "privateKey": "$privateKey",
          "shortIds": ["$shortId"]
        }
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

    echo "$uuid $serverName $publicKey $shortId"
}

# 函数：安装 Xray
install_xray() {
    # 设置变量
    # TCP_PORT_1=1080
    # TCP_PORT_2=8080

    # 检查端口是否可用且可绑定
    if ! check_port $TCP_PORT_1 tcp; then
        echo "端口 $TCP_PORT_1 不可用或无法绑定，请选择其他端口或检查权限"
        return 1
    fi
    if ! check_port $TCP_PORT_2 tcp; then
        echo "端口 $TCP_PORT_2 不可用或无法绑定，请选择其他端口或检查权限"
        return 1
    fi

    # 创建目录并进入
    mkdir -p "$HOME/xray" && cd "$HOME/xray" || { echo "创建目录失败"; return 1; }

    # 下载并解压Xray
    if ! curl -s -L -O https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-freebsd-64.zip; then
        echo "下载 Xray 失败"
        return 1
    fi
    unzip -q Xray-freebsd-64.zip
    chmod +x xray

    # 生成UUID
    local uuid1=$(generate_vless_ws_config "$TCP_PORT_1" "$HOME/xray" "config_vless_ws.json")
    read -r uuid2 serverName publicKey shortId <<< $(generate_vless_tcp_reality_vision_config "$TCP_PORT_2" "$HOME/xray" "config_vless_tcp_reality_vision.json")

    # 执行 Xray 并捕获输出
    local output=$(./xray run -c config_vless_ws.json -c config_vless_tcp_reality_vision.json 2>&1 & sleep 1; pkill -f "./xray run")
    echo "Xray 启动输出:"
    echo "$output"

    # 启动Xray
    nohup ./xray run -c config_vless_ws.json -c config_vless_tcp_reality_vision.json > /dev/null 2>&1 &
    
    # 输出 Xray 进程信息
    echo "Xray 进程信息:"
    ps aux | grep "[x]ray run -c config_vless_ws.json -c config_vless_tcp_reality_vision.json"

    # 获取服务器 IP
    local SERVER_IP=$(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
    if [ -z "$SERVER_IP" ]; then
        echo "获取服务器 IP 失败"
        return 1
    fi

    echo "Xray 配置信息"
    echo "Vless+ws 端口: $TCP_PORT_1"
    echo "Vless+ws UUID: $uuid1"
    echo "服务器 IP: $SERVER_IP"
    echo "配置链接: vless://$uuid1@$SERVER_IP:$TCP_PORT_1?encryption=none&type=ws#vless+ws"
    echo "Vless+tcp+reality 端口: $TCP_PORT_2"
    echo "Vless+tcp+reality UUID: $uuid2"
    echo "Vless+tcp+reality sni: $serverName"
    echo "Vless+tcp+reality publicKey: $publicKey"
    echo "Vless+tcp+reality shortId: $shortId"
    echo "Vless+tcp+reality 配置链接: vless://$uuid2@$SERVER_IP:$TCP_PORT_2?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$serverName&fp=safari&pbk=$publicKey&sid=$shortId&type=tcp#vless+tcp+reality"
}

# 函数：卸载 Xray
uninstall_xray() {
    pkill -f "./xray run"
    rm -rf "$HOME/xray"
    echo "Xray 已成功卸载"
}

# 函数：添加定时任务
add_crontab() {
    if [ -d "$HOME/xray" ]; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * if ! pgrep -f \"./xray run\" > /dev/null; then cd \"$HOME/xray\" && nohup ./xray run -c config_vless_ws.json -c config_vless_tcp_reality_vision.json > /dev/null 2>&1 & fi") | crontab -
        (crontab -l 2>/dev/null; echo "@reboot pkill -f \"./xray run\" && cd \"$HOME/xray\" && nohup ./xray run -c config_vless_ws.json -c config_vless_tcp_reality_vision.json > /dev/null 2>&1 &") | crontab -
        echo "Xray 定时任务已添加"
    else
        echo "错误：Xray 目录不存在，无法添加定时任务"
        return 1
    fi
}

# 函数：删除定时任务
remove_crontab() {
    crontab -l 2>/dev/null | grep -v "cd \"$HOME/xray\"" | crontab -
    echo "Xray 定时任务已删除"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo "请选择操作："
        echo "1. 安装 Xray"
        echo "2. 卸载 Xray"
        echo "3. 添加定时任务"
        echo "4. 删除定时任务"
        read -p "输入选项 (可多选，用空格分隔): " -a choices
    else
        choices=("$@")
    fi

    for choice in "${choices[@]}"; do
        case $choice in
            1)
                install_xray
                ;;
            2)
                uninstall_xray
                ;;
            3)
                add_crontab
                ;;
            4)
                remove_crontab
                ;;
            *)
                echo "无效的选项: $choice，请输入 1, 2, 3 或 4"
                ;;
        esac
    done
}

# 执行主函数
main "$@"