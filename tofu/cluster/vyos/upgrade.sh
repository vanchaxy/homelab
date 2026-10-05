#!/usr/bin/env bash
# Bring a VyOS router to the desired VyOS Stream version.
#
#   upgrade.sh <host> <version>         APPLY_MODE=apply (default) | dry-run
#
# Same version: nothing. Otherwise add the signed Stream ISO as the default boot
# image (config and SSH keys carried over), reboot, wait for SSH and verify.
set -euo pipefail

host="$1"
want="$2"
mode="${APPLY_MODE:-apply}"
ssh_cmd=(ssh -o BatchMode=yes -o ConnectTimeout=15 "vyos@${host}")
iso="https://community-downloads.vyos.dev/stream/${want}/vyos-${want}-generic-amd64.iso"

running=$("${ssh_cmd[@]}" "python3 -c 'import json;print(json.load(open(\"/usr/share/vyos/version.json\"))[\"version\"])'")
if [ "$running" = "$want" ]; then
  echo "${host}: VyOS ${running}, nothing to do"
  exit 0
fi
echo "${host}: VyOS ${running} -> ${want}"
[ "$mode" = "apply" ] || exit 0

"${ssh_cmd[@]}" "sudo /usr/libexec/vyos/op_mode/image_installer.py --action add --no-prompt --image-path ${iso}" | tail -3
"${ssh_cmd[@]}" 'sudo systemctl reboot' || true
sleep 30
for _ in $(seq 1 60); do
  now=$("${ssh_cmd[@]}" "python3 -c 'import json;print(json.load(open(\"/usr/share/vyos/version.json\"))[\"version\"])'" 2>/dev/null) && break
  sleep 10
done
[ "${now:-}" = "$want" ] || { echo "${host}: still on ${now:-unreachable} after reboot"; exit 1; }
echo "${host}: now on VyOS ${now}"
