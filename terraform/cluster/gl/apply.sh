#!/usr/bin/env bash
# Apply the GL-A1300's OpenWrt config files over SSH.
#
#   apply.sh <host>      GL_FILES (JSON path -> content), VYOS_APPLY_MODE=apply | dry-run
#
# Compares each file with the live one; no difference -> nothing. Otherwise backs
# up the current files, arms a background revert, writes the files, runs
# reload_config, reconnects to prove access survived and cancels the revert.
# The diff (passphrases masked) is left in /root/tofu/diff.txt on the GL.
set -euo pipefail

host="$1"
mode="${VYOS_APPLY_MODE:-apply}"
revert_after="${VYOS_REVERT_AFTER:-300}"
ssh_cmd=(ssh -o BatchMode=yes -o ConnectTimeout=15 -o ServerAliveInterval=5 "root@${host}")
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
umask 077

printf '%s' "$GL_FILES" > "$work/files.json"
changed=()
: > "$work/diff.txt"
for path in $(python3 -c 'import json,sys;print(" ".join(json.load(open(sys.argv[1]))))' "$work/files.json"); do
  python3 -c 'import json,sys;sys.stdout.write(json.load(open(sys.argv[1]))[sys.argv[2]])' "$work/files.json" "$path" > "$work/want"
  "${ssh_cmd[@]}" "cat $path 2>/dev/null" > "$work/have" || true
  if ! cmp -s "$work/want" "$work/have"; then
    changed+=("$path")
    diff -u --label "live $path" --label "desired $path" "$work/have" "$work/want" \
      | sed -E "s/(option key ')[^']*'/\1<masked>'/" >> "$work/diff.txt" || true
  fi
done

"${ssh_cmd[@]}" 'mkdir -p /root/tofu && cat > /root/tofu/diff.txt' < "$work/diff.txt"
if [ ${#changed[@]} -eq 0 ]; then
  echo "${host}: no changes"
  exit 0
fi
echo "${host}: changes in ${changed[*]}"
[ "$mode" = "apply" ] || exit 0

stamp=$(date +%Y%m%d%H%M%S)
"${ssh_cmd[@]}" "mkdir -p /root/tofu/backup-${stamp} && cp /etc/config/* /root/tofu/backup-${stamp}/ \
  && start-stop-daemon -S -b -m -p /tmp/tofu-revert.pid -x /bin/sh -- -c \
     'sleep ${revert_after}; cp /root/tofu/backup-${stamp}/* /etc/config/; reload_config; wifi reload'"
for path in "${changed[@]}"; do
  python3 -c 'import json,sys;sys.stdout.write(json.load(open(sys.argv[1]))[sys.argv[2]])' "$work/files.json" "$path" \
    | "${ssh_cmd[@]}" "cat > ${path}.tofu && mv ${path}.tofu ${path}"
done
"${ssh_cmd[@]}" 'reload_config; wifi reload' || true
sleep 15
"${ssh_cmd[@]}" 'kill $(cat /tmp/tofu-revert.pid) 2>/dev/null; rm -f /tmp/tofu-revert.pid; echo "verified access, revert cancelled"'
