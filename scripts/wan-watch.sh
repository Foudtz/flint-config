#!/bin/sh
# Journalise les changements du lien WAN (eth1) : carrier, vitesse, nb de coupures
D=/sys/class/net/eth1
LOG=/root/wan-link.log
STATE=/tmp/wan-watch.state
cur="$(cat $D/carrier 2>/dev/null) $(cat $D/speed 2>/dev/null) $(cat $D/carrier_down_count 2>/dev/null)"
prev="$(cat $STATE 2>/dev/null)"
if [ "$cur" != "$prev" ]; then
  echo "$(date '+%F %T') carrier speed downs = $cur" >> $LOG
  echo "$cur" > $STATE
fi
