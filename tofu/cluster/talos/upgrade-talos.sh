#!/usr/bin/env bash
# Upgrade Talos on the nodes, strictly one node at a time.
#
#   upgrade-talos.sh <version> <installer-image> <name=ip>...   UPGRADE_MODE=apply | dry-run
#
# Per node: skip if already on <version>; refuse jumps of more than one minor
# version; check the cluster is healthy; drain (best effort); talosctl upgrade
# --preserve --wait; wait for the node to be Ready on the new version, etcd to
# have all members healthy and Longhorn to have no degraded volumes; uncordon.
# Any failure stops the loop, so at most one node is ever mid-upgrade.
set -euo pipefail

want="$1"; image="$2"; shift 2
mode="${UPGRADE_MODE:-apply}"
longhorn_timeout="${LONGHORN_WAIT_TIMEOUT:-5400}"

minor() { echo "$1" | sed -E 's/^v?([0-9]+)\.([0-9]+).*/\1 \2/'; }
talos_version() { talosctl -n "$1" version 2>/dev/null | awk '/Server:/{s=1} s && /Tag:/{print $2; exit}'; }

check_jump() {
  read -r ma mi <<<"$(minor "$1")"; read -r wa wi <<<"$(minor "$2")"
  if [ "$wa" != "$ma" ] || [ $((wi - mi)) -gt 1 ] || [ $((wi - mi)) -lt 0 ]; then
    echo "refusing $1 -> $2: Talos must be upgraded one minor version at a time, never downgraded"; exit 1
  fi
}

cluster_healthy() {
  local notready
  notready=$(kubectl get nodes --no-headers | awk '$2 !~ /^Ready/ {print $1}')
  [ -z "$notready" ] || { echo "nodes not Ready: $notready"; return 1; }
  [ "$(talosctl -n "$1" etcd members 2>/dev/null | grep -c 'false$')" -ge "$#" ] || { echo "etcd does not show all members"; return 1; }
}

wait_longhorn() {
  local deadline=$(( $(date +%s) + longhorn_timeout ))
  while :; do
    degraded=$(kubectl -n longhorn-system get volumes.longhorn.io -o jsonpath='{range .items[?(@.status.robustness=="degraded")]}{.metadata.name} {end}' 2>/dev/null || true)
    [ -z "$degraded" ] && return 0
    [ "$(date +%s)" -lt "$deadline" ] || { echo "Longhorn still degraded after ${longhorn_timeout}s: $degraded"; return 1; }
    echo "  waiting for Longhorn rebuilds: $(echo $degraded | wc -w) degraded volume(s)"; sleep 60
  done
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
  kubectl drain "$name" --ignore-daemonsets --delete-emptydir-data --timeout=300s >/dev/null 2>&1 \
    || echo "  drain did not finish in 5m (e.g. single-replica PDBs), continuing; the reboot stops the rest"
  talosctl -n "$ip" upgrade --image "$image" --preserve --wait --timeout 30m
  kubectl wait --for=condition=Ready "node/${name}" --timeout=900s >/dev/null
  now=$(talos_version "$ip")
  [ "$now" = "$want" ] || { echo "${name}: still on ${now} after the upgrade"; exit 1; }
  kubectl uncordon "$name" >/dev/null
  cluster_healthy "${ips[@]}"
  wait_longhorn
  echo "${name}: now on Talos ${now}, cluster healthy"
done
