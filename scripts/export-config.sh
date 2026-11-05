#!/bin/sh
# Copie /etc/config dans /tmp/cfg-export en masquant les secrets
OUT=/tmp/cfg-export
rm -rf "$OUT" && mkdir -p "$OUT"
cp /etc/config/* "$OUT"/
sed -i -E "s/^([[:space:]]*(option|list)[[:space:]]+(key|password|private_key|preshared_key|sae_password|auth_secret)[[:space:]]+).*/\1'REDACTED'/" "$OUT"/*
cp /etc/openwrt_release "$OUT"/_openwrt_release
[ -f /etc/apk/world ] && cp /etc/apk/world "$OUT"/_apk_world
exit 0
