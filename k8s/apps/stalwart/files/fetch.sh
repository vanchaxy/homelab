#!/bin/sh
set -eu

rcdir=/tmp/getmailrc
statedir=/var/lib/stalwart/getmail
mkdir -p "$rcdir" "$statedir"

write_rc() {
  name=$1 server=$2 user=$3 password=$4 target=$5 mailbox=$6 port=$7
  cat > "$rcdir/$name" <<EOF
[retriever]
type = SimpleIMAPSSLRetriever
server = $server
username = $user
password = $password
mailboxes = ("$mailbox",)

[destination]
type = MDA_lmtp
host = 127.0.0.1
port = $port
override = $target

[options]
read_all = false
delete = false
received = false
delivered_to = false
verbose = 1
EOF
}

while IFS='|' read -r name server prefix target inbox junk; do
  [ -n "$name" ] || continue
  eval "user=\${${prefix}_USER}"
  eval "password=\${${prefix}_PASSWORD}"
  write_rc "$name-inbox" "$server" "$user" "$password" "$target" "$inbox" 24
  write_rc "$name-junk" "$server" "$user" "$password" "$target" "$junk" 26
done < /config/sources

while true; do
  for rc in "$rcdir"/*; do
    python /opt/getmail/bin/getmail --getmaildir "$statedir" --rcfile "$rc" || echo "getmail failed for $(basename "$rc")"
  done
  sleep "${FETCH_INTERVAL:-120}"
done
