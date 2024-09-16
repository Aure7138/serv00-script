#!/bin/bash

# 安装 Hysteria2
install_hysteria2() {
    # 设置变量
    # UDP_PORT=8080
    PASSWORD=$(openssl rand -base64 12)

    # 创建目录并进入
    mkdir -p "$HOME/hysteria2" && cd "$HOME/hysteria2" > /dev/null 2>&1

    # 下载 Hysteria
    curl -s -L -O https://github.com/apernet/hysteria/releases/latest/download/hysteria-freebsd-amd64 > /dev/null 2>&1
    chmod +x hysteria-freebsd-amd64

    # 生成证书
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout server.key -out server.crt -subj "/CN=bing.com" -days 36500 > /dev/null 2>&1

    # 创建配置文件
    cat <<EOF > config.yaml
listen: :$UDP_PORT

tls:
  cert: "$HOME/hysteria2/server.crt"
  key: "$HOME/hysteria2/server.key"

auth:
  type: password
  password: $PASSWORD
  
masquerade:
  type: proxy
  proxy:
    url: https://bing.com
    rewriteHost: true
EOF

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
    echo 服务器 IP: $(curl -s ifconfig.me || curl -s ifconfig.co || curl -s ifconfig.me/ip || curl -s ifconfig.co/ip || curl -s ipinfo.io/ip)
}

# 卸载 Hysteria2
uninstall_hysteria2() {
    pkill -f "./hysteria-freebsd-amd64 server -c config.yaml" > /dev/null 2>&1
    rm -rf "$HOME/hysteria2" > /dev/null 2>&1
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
