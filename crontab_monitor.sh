# 检查并添加 crontab 任务以保活各个进程和监控系统重启

crontab -r

# 设置 xray 所在的目录路径
xray_dir="~/xray"

# 添加新的保活任务
(crontab -l 2>/dev/null; echo "*/5 * * * * if ! pgrep -x \"xray\" > /dev/null; then cd $xray_dir && nohup ./xray run -config config.json > /dev/null 2>&1 & fi") | crontab -

# 添加新的重启后自动启动任务
(crontab -l 2>/dev/null; echo "@reboot pkill -f \"xray run -config config.json\" && cd $xray_dir && nohup ./xray run -config config.json > /dev/null 2>&1 &") | crontab -
