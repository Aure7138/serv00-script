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

    echo $pid >/dev/null 2>&1

    ps aux >/dev/null 2>&1

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

# 生成 Hysteria2 配置函数
generate_hysteria2_config() {
    local port="$1"
    local path="$2"
    local filename="$3"
    local password

    # 生成密码
    password=$(openssl rand -base64 16)

    # 生成证书
    if ! openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout "$path/server.key" -out "$path/server.crt" -subj "/CN=bing.com" -days 36500 2>/dev/null; then
        echo "生成证书失败"
        return 1
    fi

    # 创建配置文件
    cat <<EOF > "$path/$filename"
listen: :$port

tls:
  cert: $path/server.crt
  key: $path/server.key

auth:
  type: password
  password: $password
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

    echo "$password"
}

# 安装 Hysteria2
install_hysteria2() {
    # 检查端口是否可用且可绑定
    if ! check_port $UDP_PORT udp; then
        echo "端口 $UDP_PORT 不可用或无法绑定，请选择其他端口或检查权限"
        return 1
    fi

    # 创建目录并进入
    mkdir -p "$HOME/hysteria2" && cd "$HOME/hysteria2" || { echo "创建目录失败"; return 1; }

    # 下载 Hysteria
    if ! curl -s -L -O https://github.com/apernet/hysteria/releases/latest/download/hysteria-freebsd-amd64; then
        echo "下载 Hysteria 失败"
        return 1
    fi
    chmod +x hysteria-freebsd-amd64

    # 获取服务器 IP
    SERVER_IP=$(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
    if [ -z "$SERVER_IP" ]; then
        echo "获取服务器 IP 失败"
        return 1
    fi

    # 生成配置并获取密码
    PASSWORD=$(generate_hysteria2_config "$UDP_PORT" "$HOME/hysteria2" "config.yaml")
    if [ $? -ne 0 ]; then
        echo "生成配置失败"
        return 1
    fi

    # 执行 Hysteria2 并捕获输出
    output=$(./hysteria-freebsd-amd64 server -c config.yaml 2>&1 & sleep 1; pkill -f "./hysteria-freebsd-amd64 server -c config.yaml")
    echo "Hysteria2 启动输出:"
    echo "$output"

    # 启动 Hysteria
    nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 &

    # 输出 Hysteria2 进程信息
    echo "Hysteria2 进程信息:"
    ps aux | grep "[h]ysteria-freebsd-amd64 server -c config.yaml"

    echo "Hysteria2 配置信息"
    echo "UDP端口: $UDP_PORT"
    echo "密码: $PASSWORD"
    echo "服务器 IP: $SERVER_IP"
    echo "配置链接: hysteria2://$PASSWORD@$SERVER_IP:$UDP_PORT/?sni=bing.com&insecure=1#hysteria2"
}

# 卸载 Hysteria2
uninstall_hysteria2() {
    pkill -f "./hysteria-freebsd-amd64 server -c config.yaml"
    rm -rf "$HOME/hysteria2"
    echo "Hysteria2 已成功卸载"
}

# 添加定时任务
add_crontab() {
    if [ -d "$HOME/hysteria2" ]; then
        (crontab -l 2>/dev/null; echo "*/5 * * * * if ! pgrep -f \"./hysteria-freebsd-amd64 server -c config.yaml\" > /dev/null; then cd \"$HOME/hysteria2\" && nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 & fi") | crontab -
        (crontab -l 2>/dev/null; echo "@reboot pkill -f \"./hysteria-freebsd-amd64 server -c config.yaml\" && cd \"$HOME/hysteria2\" && nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 &") | crontab -
    fi
    echo "Hysteria2 定时任务已添加"
}

# 删除定时任务
remove_crontab() {
    crontab -l 2>/dev/null | grep -v "cd \"$HOME/hysteria2\" && nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 &" | crontab -
    echo "Hysteria2 定时任务已删除"
}

# 主函数
main() {
    if [ $# -eq 0 ]; then
        echo "请选择操作："
        echo "1. 安装 Hysteria2"
        echo "2. 卸载 Hysteria2"
        echo "3. 添加定时任务"
        echo "4. 删除定时任务"
        read -p "输入选项 (可多选，用空格分隔): " -a choices
    else
        choices=("$@")
    fi

    for choice in "${choices[@]}"; do
        case $choice in
            1)
                install_hysteria2
                ;;
            2)
                uninstall_hysteria2
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
