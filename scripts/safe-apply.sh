#!/bin/sh
# safe-apply.sh arm [secondes] | confirm | status | restore
PKGS="firewall dropbear uhttpd dhcp network"
SNAP=/root/.safe-apply
PID=/var/run/safe-apply.pid

armed() { [ -f "$PID" ] && kill -0 "$(cat "$PID")" 2>/dev/null; }

case "$1" in
  arm)
    DELAY="${2:-180}"
    armed && { echo "Déjà armé (pid $(cat "$PID"))"; exit 1; }
    rm -rf "$SNAP"; mkdir -p "$SNAP"
    for p in $PKGS; do cp -p "/etc/config/$p" "$SNAP/"; done
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
    rm -f "$PID"
    logger -t safe-apply "Retour arrière fait :${CHANGED:- rien à restaurer}"
    ;;
  *) echo "Usage : $0 arm [secondes] | confirm | status"; exit 1 ;;
esac
