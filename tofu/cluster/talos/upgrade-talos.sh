#!/usr/bin/env bash
# Upgrade Talos on the nodes, strictly one node at a time.
#
#   upgrade-talos.sh <version> <installer-image> <name=ip>...   APPLY_MODE=apply | dry-run
#
# Per node: skip if already on <version>; refuse jumps of more than one minor
# version; check the cluster is healthy; pre-pull the installer
# into the system namespace (a legacy Upgrade RPC fallback blocks silently while it
# pulls, and a newer talosctl's keepalive pings get the connection killed with
# too_many_pings, cancelling the pull); talosctl upgrade --wait
# (Talos cordons and drains the node itself, and uncordons it after boot);
# wait for the node to be Ready on the new version (retrying while the API is
# down, since the endpoint is mars itself), etcd to have all members healthy
# and Longhorn to have no degraded volumes.
# Any failure stops the loop, so at most one node is ever mid-upgrade.
set -euo pipefail
. "$(dirname "$0")/node-lib.sh"

want="$1"; image="$2"; shift 2
mode="${APPLY_MODE:-apply}"

minor() { echo "$1" | sed -E 's/^v?([0-9]+)\.([0-9]+).*/\1 \2/'; }

check_jump() {
  read -r ma mi <<<"$(minor "$1")"; read -r wa wi <<<"$(minor "$2")"
  if [ "$wa" != "$ma" ] || [ $((wi - mi)) -gt 1 ] || [ $((wi - mi)) -lt 0 ]; then
    echo "refusing $1 -> $2: Talos must be upgraded one minor version at a time, never downgraded"; exit 1
  fi
}

client=$(talosctl version --client 2>/dev/null | awk '/Tag:/{print $2; exit}')
[ "$client" = "$want" ] || echo "note: talosctl client is ${client}, nodes go to ${want}; update talosctl to match"

ips=(); for p in "$@"; do ips+=("${p#*=}"); done
for pair in "$@"; do
  name="${pair%%=*}"; ip="${pair#*=}"
  have=$(talos_version "$ip")
  if [ "$have" = "$want" ]; then echo "${name}: Talos ${have}, nothing to do"; continue; fi
  check_jump "$have" "$want"
  echo "${name}: Talos ${have} -> ${want}"
  [ "$mode" = "apply" ] || continue

  cluster_healthy "${ips[@]}"
  wait_longhorn
  for i in 1 2 3; do talosctl -n "$ip" image pull --namespace system "$image" && break; [ "$i" -lt 3 ] || exit 1; sleep 10; done
  talosctl -n "$ip" upgrade --image "$image" --wait --timeout 30m --drain-timeout 15m
  wait_ready "$name"
  now=$(talos_version "$ip")
  [ "$now" = "$want" ] || { echo "${name}: still on ${now} after the upgrade"; exit 1; }
  cluster_healthy "${ips[@]}"
  wait_longhorn
  echo "${name}: now on Talos ${now}, cluster healthy"
done
