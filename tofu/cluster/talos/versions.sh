#!/usr/bin/env bash
# Report the running Talos (lowest across the nodes) and Kubernetes versions
# as JSON, for the plan-time version-jump preconditions.
#
#   versions.sh <node-ip>...
set -euo pipefail

talos=$(for ip in "$@"; do
  v=$(talosctl -n "$ip" version 2>/dev/null | awk '/Server:/{s=1} s && /Tag:/{print $2; exit}')
  [ -n "$v" ] || { echo "cannot read the Talos version of $ip" >&2; exit 1; }
  echo "$v"
done | sort -V | head -1)

kubernetes=$(kubectl version -o json | python3 -c 'import json,sys;print(json.load(sys.stdin)["serverVersion"]["gitVersion"])')

printf '{"talos":"%s","kubernetes":"%s"}\n' "$talos" "$kubernetes"
