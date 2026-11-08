#!/bin/sh
# banc.sh up | down | status  -- namespaces de test t20..t70 sur eno1
VLANS="20 30 40 50 60 70"
IF=eno1
case "$1" in
  up)
    for v in $VLANS; do
      ns=t$v
      [ -e /run/netns/$ns ] && continue
      ip link add link $IF name $IF.$v type vlan id $v
      ip netns add $ns
      ip link set $IF.$v netns $ns
      ip -n $ns link set lo up
      ip -n $ns link set $IF.$v up
      ip -n $ns addr add 10.10.$v.254/24 dev $IF.$v
      ip -n $ns route add default via 10.10.$v.1
      mkdir -p /etc/netns/$ns
      printf 'nameserver 10.10.%s.1\n' $v > /etc/netns/$ns/resolv.conf
    done ;;
  down)
    for v in $VLANS; do ip netns del t$v 2>/dev/null; rm -rf /etc/netns/t$v; done ;;
  status)
    for v in $VLANS; do
      printf 't%s (10.10.%s.254) : ' $v $v
      ip netns exec t$v ping -c 1 -W 2 10.10.$v.1 >/dev/null 2>&1 && echo OK || echo KO
    done ;;
  *) echo "Usage : $0 up | down | status"; exit 1 ;;
esac
