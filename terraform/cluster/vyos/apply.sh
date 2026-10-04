#!/usr/bin/env bash
# Apply a complete VyOS config (set commands) declaratively over SSH.
#
#   apply.sh <host> <config-file>        VYOS_APPLY_MODE=apply (default) | dry-run
#
# On the router: delete every top-level node, source the desired set commands
# and print `compare`. VyOS commits only the difference, so unchanged parts are
# not touched. No difference -> discard. Otherwise commit with an auto-revert
# armed, reconnect to prove access survived, then cancel the revert and save.
set -euo pipefail

host="$1"
config="$2"
mode="${VYOS_APPLY_MODE:-apply}"
revert_after="${VYOS_REVERT_AFTER:-300}"
ssh_cmd=(ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=5 "vyos@${host}")

"${ssh_cmd[@]}" 'mkdir -p /config/tofu && cat > /config/tofu/desired.sh' < "$config"

"${ssh_cmd[@]}" "MODE=${mode} REVERT_AFTER=${revert_after} bash -s" <<'REMOTE'
set -euo pipefail
cd /config/tofu
cat > run.sh <<'VBASH'
#!/bin/vbash
source /opt/vyatta/etc/functions/script-template
configure
for node in $(cli-shell-api listActiveNodes | tr -d "'"); do
  delete "$node"
done
source /config/tofu/desired.sh
compare > /config/tofu/compare.txt 2>&1
if grep -q "No changes between working and active configurations" /config/tofu/compare.txt \
   || [ ! -s /config/tofu/compare.txt ] || [ "$MODE" != "apply" ]; then
  discard
else
  sudo systemctl stop tofu-revert.timer 2>/dev/null || true
  sudo systemd-run --unit=tofu-revert --on-active="$REVERT_AFTER" \
    sg vyattacfg -c "/bin/vbash /config/tofu/revert.sh" >/dev/null 2>&1
  commit
  echo committed > /config/tofu/state
fi
exit
VBASH
cat > revert.sh <<'VBASH'
#!/bin/vbash
source /opt/vyatta/etc/functions/script-template
configure
load /config/config.boot
commit
exit
VBASH
sed -i "2i MODE=${MODE}; REVERT_AFTER=${REVERT_AFTER}" run.sh
cat > save.sh <<'VBASH'
#!/bin/vbash
source /opt/vyatta/etc/functions/script-template
configure
save
exit
VBASH
chmod 700 run.sh revert.sh save.sh
rm -f state
sg vyattacfg -c "/bin/vbash /config/tofu/run.sh" >/config/tofu/run.log 2>&1 || { cat /config/tofu/run.log; exit 1; }
echo "----- diff (VyOS compare) on $(hostname) -----"
cat compare.txt
[ -f state ] && echo "STATE: committed, auto-revert in ${REVERT_AFTER}s" || echo "STATE: nothing committed (${MODE})"
REMOTE

if "${ssh_cmd[@]}" 'test -f /config/tofu/state'; then
  sleep 5
  "${ssh_cmd[@]}" 'sudo systemctl stop tofu-revert.timer; sg vyattacfg -c "/bin/vbash /config/tofu/save.sh" >/dev/null; rm -f /config/tofu/state; echo "verified access, saved"'
fi
