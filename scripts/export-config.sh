#!/bin/sh
# Copie /etc/config dans /tmp/cfg-export en masquant les secrets
# Scripts de /root dans /tmp/cfg-export-scripts
OUT=/tmp/cfg-export
SCR=/tmp/cfg-export-scripts
rm -rf "$OUT" "$SCR" && mkdir -p "$OUT" "$SCR"
cp /etc/config/* "$OUT"/
sed -i -E "s/^([[:space:]]*(option|list)[[:space:]]+(key|password|private_key|preshared_key|sae_password|auth_secret)[[:space:]]+).*/\1'REDACTED'/" "$OUT"/*
cp /etc/openwrt_release "$OUT"/_openwrt_release
[ -f /etc/apk/world ] && cp /etc/apk/world "$OUT"/_apk_world
# AdGuard Home : hachage du mot de passe et clé TLS masqués
if [ -f /etc/adguardhome/adguardhome.yaml ]; then
  sed -E "s/^([[:space:]]*(password|private_key):[[:space:]]*).+/\1REDACTED/" \
    /etc/adguardhome/adguardhome.yaml > "$OUT"/_adguardhome.yaml
fi
cp /etc/crontabs/root "$OUT"/_crontab_root
cp /etc/sysupgrade.conf "$OUT"/_sysupgrade.conf
for f in safe-apply.sh dns-watchdog.sh export-config.sh wan-watch.sh; do
  [ -f "/root/$f" ] && cp "/root/$f" "$SCR"/
done
exit 0
