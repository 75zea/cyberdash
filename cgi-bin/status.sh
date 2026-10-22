#!/bin/bash
# status.sh — CGI simple renvoyant le statut système en JSON.
# À placer dans /usr/lib/cgi-bin/ ou /var/www/cgi-bin/ selon la config nginx.
# Nécessite uniquement : date, uptime, free, df.

set -euo pipefail

UPTIME=$(uptime -p 2>/dev/null || sed 's/^up //' /proc/uptime)
LOAD=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ //' | cut -d',' -f1)
MEM_TOTAL=$(free -m | awk '/Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/Mem:/ {print $3}')
DISK=$(df -h / | awk 'NR==2 {print $5}')

cat <<EOF
Content-Type: application/json

{"uptime":"$UPTIME","load":"$LOAD","mem":"${MEM_USED} / ${MEM_TOTAL} Mo","disk":"$DISK"}
EOF
