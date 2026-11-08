#!/bin/sh
# Si AdGuard ne répond plus 2 minutes de suite : dnsmasq reprend le port 53.
# Pause pour maintenance : touch /root/dns-watchdog.off
STATE=/tmp/dns-watchdog.fail
[ -f /root/dns-watchdog.off ] && exit 0
[ "$(uci -q get dhcp.@dnsmasq[0].port)" = "54" ] || exit 0   # déjà en secours
if nslookup adguard-check.internal 127.0.0.1 2>/dev/null | grep -q '127\.0\.0\.2'; then
  rm -f "$STATE"; exit 0
fi
N=$(( $(cat "$STATE" 2>/dev/null || echo 0) + 1 )); echo "$N" > "$STATE"
logger -t dns-watchdog "AdGuard ne répond pas (échec $N)"
[ "$N" -ge 2 ] || exit 0
/etc/init.d/adguardhome stop
uci set dhcp.@dnsmasq[0].port='53'; uci commit dhcp
/etc/init.d/dnsmasq restart
rm -f "$STATE"
logger -t dns-watchdog "SECOURS : AdGuard arrêté, dnsmasq repris sur le port 53 (sans filtrage)"
