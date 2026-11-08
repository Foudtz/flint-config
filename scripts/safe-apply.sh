#!/bin/sh
# safe-apply.sh arm [secondes] | confirm | status | restore
PKGS="firewall dropbear uhttpd dhcp network"
AGH=/etc/adguardhome/adguardhome.yaml
SNAP=/root/.safe-apply
PID=/var/run/safe-apply.pid

armed() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; }

case "$1" in
  arm)
    DELAY="${2:-180}"
    armed && { echo "Déjà armé (pid $(cat "$PID"))"; exit 1; }
    rm -rf "$SNAP"; mkdir -p "$SNAP"
    for p in $PKGS; do cp -p "/etc/config/$p" "$SNAP/"; done
    [ -f "$AGH" ] && cp -p "$AGH" "$SNAP/adguardhome.yaml"
    start-stop-daemon -S -b -m -p "$PID" -x /bin/sh -- -c "sleep $DELAY; /root/safe-apply.sh restore"
    logger -t safe-apply "Armé pour ${DELAY}s"
    echo "Armé : retour arrière dans ${DELAY}s, sauf '/root/safe-apply.sh confirm'"
    ;;
  confirm)
    if armed; then
      start-stop-daemon -K -p "$PID" -q; rm -f "$PID"
      logger -t safe-apply "Confirmé"; echo "Confirmé, retour arrière annulé"
    else
      echo "Rien à annuler"
    fi
    ;;
  status)
    armed && echo "Armé (pid $(cat "$PID"))" || echo "Non armé"
    ;;
  restore)
    CHANGED=""
    AGH_CHANGED=0
    # 1. AdGuard d'abord : il doit libérer le port 53 avant que dnsmasq le reprenne
    if [ -f "$SNAP/adguardhome.yaml" ] && ! cmp -s "$AGH" "$SNAP/adguardhome.yaml"; then
      /etc/init.d/adguardhome stop
      cp -p "$SNAP/adguardhome.yaml" "$AGH"
      AGH_CHANGED=1; CHANGED="$CHANGED adguardhome"
    fi
    # 2. Fichiers UCI
    for p in $PKGS; do
      uci -q revert "$p"
      if ! cmp -s "/etc/config/$p" "$SNAP/$p"; then
        cp -p "$SNAP/$p" "/etc/config/$p"; CHANGED="$CHANGED $p"
      fi
    done
    for p in $CHANGED; do
      case "$p" in
        firewall) /etc/init.d/firewall restart ;;
        dropbear) /etc/init.d/dropbear restart ;;
        uhttpd)   /etc/init.d/uhttpd restart ;;
        dhcp)     /etc/init.d/dnsmasq restart ;;
        network)  /etc/init.d/network reload ;;
      esac
    done
    # 3. AdGuard relancé en dernier, avec l'ancienne config
    [ "$AGH_CHANGED" = 1 ] && /etc/init.d/adguardhome start
    rm -f "$PID"
    logger -t safe-apply "Retour arrière fait :${CHANGED:- rien à restaurer}"
    ;;
  *) echo "Usage : $0 arm [secondes] | confirm | status"; exit 1 ;;
esac
