#!/usr/bin/bash

# https://learn.microsoft.com/en-us/windows/terminal/command-line-arguments?tabs=linux

# Define your terminal executable and command configurations
terminal_exe="wt.exe"  # Windows Terminal executable (use 'wt.exe' for Windows Terminal)

# Using a one-liner to repeat the "=" string
spacer=$(printf '=%.0s' {1..80})

# Set a sleep time between each remote request
sleep=0.5

# F00 - Red
# FF7F00 - Orange
# FFFF00 - Yellow
# 00FF00 - Green
# 007FFF - Blue
# 7F00FF - Purple
# 00FFFF - Cyan
# 808080 - Gray

# Status-related commands
$terminal_exe -w monitor nt --title "systemctl" --tabColor "#00FF00" ssh acdeco -t \
    "systemctl status apache2 && echo $spacer \
    && systemctl status php7.3-fpm && echo $spacer \
    && systemctl status mysql && echo $spacer \
    && w && echo $spacer \
    && df -h && echo $spacer \
    && /bin/bash" \
    && sleep "$sleep"

# Monitoring commands
$terminal_exe -w monitor nt --title "htop" --tabColor "#00FF00" ssh -t acdeco "htop" && sleep "$sleep"
$terminal_exe -w monitor nt --title "tcpdump" --tabColor "#FF7F00" ssh -t acdeco "tcpdump -i ens5 port 443" && sleep "$sleep"
$terminal_exe -w monitor nt --title "iftop" --tabColor "#FF7F00" ssh -t acdeco "iftop -i any" && sleep "$sleep"

# Log-related commands
$terminal_exe -w monitor nt --title "messages" --tabColor "#FFFF00" ssh -t acdeco "tail -f /var/log/messages && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "access" --tabColor "#00FFFF" ssh -t acdeco "tail -f /data/web/acdeco_prod/logs/access.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "error" --tabColor "#F00" ssh -t acdeco "tail -f /data/web/acdeco_prod/logs/error.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "php" --tabColor "#007FFF" ssh -t acdeco "tail -f /var/log/php7.3-fpm.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "memcached" --tabColor "#007FFF" ssh -t acdeco "tail -f /var/log/memcached.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "mysql" --tabColor "#F00" ssh -t acdeco "tail -f /var/log/mysql/error.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "prestashop" --tabColor "#007FFF" ssh -t acdeco "tail -f /var/log/cron.log && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "cron" --tabColor "#7F00FF" ssh -t acdeco "tail -f /data/web/acdeco_prod/www/var/logs/*.log && /bin/bash" && sleep "$sleep"

# Miscellaneous commands
$terminal_exe -w monitor nt --title "www" --tabColor "#FFFF00" ssh -t acdeco "cd /data/web/acdeco_prod/www && /bin/bash" && sleep "$sleep"
$terminal_exe -w monitor nt --title "acdeco1" --tabColor "#FFFF00" ssh -t acdeco "cat /etc/motd && /bin/bash" && sleep

# Web-related command
$terminal_exe -w monitor nt --title "ttfb" --tabColor "#808080" curl -o /dev/null -s -w "Time to first byte: %{time_total}s\n" https://www.ac-deco.com && bash
