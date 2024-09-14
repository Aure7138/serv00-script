# 检查并添加 crontab 任务以保活各个进程和监控系统重启

crontab -r -f &>/dev/null

# 设置 xray 所在的目录路径
xray_dir="$HOME/xray"

# 判断目录是否存在
if [ -d "$xray_dir" ]; then
    # 添加新的保活任务
    (crontab -l 2>/dev/null; echo "*/5 * * * * if ! pgrep -x \"xray\" > /dev/null; then cd $xray_dir && nohup ./xray run -c config.json > /dev/null 2>&1 & fi") | crontab -

    # 添加新的重启后自动启动任务
    (crontab -l 2>/dev/null; echo "@reboot pkill -f \"./xray run -c config.json\" && cd $xray_dir && nohup ./xray run -c config.json > /dev/null 2>&1 &") | crontab -
fi

hysteria2_dir="$HOME/hysteria2"

if [ -d "$hysteria2_dir" ]; then
    (crontab -l 2>/dev/null; echo "*/5 * * * * if ! pgrep -x \"hysteria-freebsd-amd64\" > /dev/null; then cd $hysteria2_dir && nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 & fi") | crontab -
    (crontab -l 2>/dev/null; echo "@reboot pkill -f \"./hysteria-freebsd-amd64 server -c config.yaml\" && cd $hysteria2_dir && nohup ./hysteria-freebsd-amd64 server -c config.yaml > /dev/null 2>&1 &") | crontab -
fi