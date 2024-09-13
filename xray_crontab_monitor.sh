# 检查并添加 crontab 任务以保活 xray 程序和监控系统重启

# 设置 xray 所在的目录路径
xray_dir="/home/$(whoami)/xray"

# 检查保活任务是否已存在
if ! crontab -l 2>/dev/null | grep -q "if ! pgrep -x \"xray\" > /dev/null; then cd $xray_dir && nohup ./xray run"
then
    # 如果任务不存在，则添加新的 crontab 任务
    (crontab -l 2>/dev/null; echo "*/12 * * * * if ! pgrep -x \"xray\" > /dev/null; then cd $xray_dir && nohup ./xray run -config config.json > /dev/null 2>&1 & fi") | crontab - >/dev/null 2>&1
fi

# 检查重启后自动启动任务是否已存在
if ! crontab -l 2>/dev/null | grep -q "@reboot pkill -f \"xray run -config config.json\" && cd $xray_dir && nohup ./xray run"
then
    # 如果任务不存在，则添加新的 crontab 任务
    (crontab -l 2>/dev/null; echo "@reboot pkill -f \"xray run -config config.json\" && cd $xray_dir && nohup ./xray run -config config.json > /dev/null 2>&1 &") | crontab - >/dev/null 2>&1
fi
