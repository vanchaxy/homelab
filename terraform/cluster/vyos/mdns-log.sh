#!/bin/sh
# Decode IPv4 mDNS on the VLAN interfaces into one syslog line per packet (tag mdns, facility local5).
apk add --no-cache tcpdump >/dev/null 2>&1 || { sleep 30; exit 1; }
tcpdump -lnni any -vv "ip and udp port 5353" 2>/dev/null | awk '
  /^[0-9][0-9]:/ { iface=$2; next }
  /\.5353 >/ { if (iface ~ /^br|\./) { sub(/^[ \t]+/, ""); print "iface=" iface " " $0; fflush() } }
' | logger -t mdns -p local5.info
