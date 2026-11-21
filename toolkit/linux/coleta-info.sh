#!/usr/bin/env bash
# ------------------------------------------------------------
# coleta-info.sh
# Versao Linux do coleta-info.bat: junta num arquivo o estado do
# servidor (sistema, CPU, memoria, disco, rede, portas, servicos
# com falha, ultimos logins e processos que mais consomem).
#
# Uso: ./coleta-info.sh [pasta-de-destino]
# Dica: rode com sudo para ver o processo dono de cada porta.
# ------------------------------------------------------------
set -u

DEST="${1:-$HOME}"
mkdir -p "$DEST"
OUT="$DEST/info_$(hostname)_$(date +%Y%m%d_%H%M).txt"

secao() {
    {
        echo
        echo "============================================================"
        echo " $1"
        echo "============================================================"
    } >> "$OUT"
}

rodar() {
    if command -v "$1" > /dev/null 2>&1; then
        "$@" >> "$OUT" 2>&1
    else
        echo "($1 nao encontrado)" >> "$OUT"
    fi
}

echo "Relatorio de $(hostname) - $(date)" > "$OUT"

secao "SISTEMA"
if [ -r /etc/os-release ]; then
    grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release >> "$OUT"
fi
rodar uname -a
rodar uptime

secao "CPU E MEMORIA"
rodar nproc
rodar free -h

secao "DISCOS"
rodar df -hT -x tmpfs -x devtmpfs

secao "REDE"
rodar ip -brief address
rodar ip route
if [ -r /etc/resolv.conf ]; then
    grep -E '^(nameserver|search)' /etc/resolv.conf >> "$OUT"
fi

secao "PORTAS ESCUTANDO"
rodar ss -tulpn

secao "SERVICOS COM FALHA"
rodar systemctl --failed --no-pager

secao "ULTIMOS LOGINS"
rodar last -n 15

secao "PROCESSOS QUE MAIS USAM CPU"
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu | head -n 11 >> "$OUT" 2>&1

secao "ERROS RECENTES NO JOURNAL (ULTIMAS 24 HORAS)"
rodar journalctl -p err --since "24 hours ago" --no-pager -n 30

echo "Pronto. Relatorio salvo em: $OUT"
