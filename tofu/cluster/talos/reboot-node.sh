#!/usr/bin/env bash
# Reboot one node so it picks up config that only takes effect at boot
# (etcd, environment, kernel modules, volume encryption, workload isolation;
# Talos 1.14 applies everything live and never reboots on its own).
#
#   reboot-node.sh <name> <ip> <all node ips>...   APPLY_MODE=apply | dry-run
#
# Check the cluster is healthy and Longhorn has no degraded volumes; reboot;
# wait for Ready, etcd and Longhorn again. Tofu chains the per-node calls, so
# at most one node is ever rebooting.
# No drain: Talos stops all pods gracefully before a reboot and the node is
# back within minutes (siderolabs/talos#9603).
set -euo pipefail
. "$(dirname "$0")/node-lib.sh"

name="$1"; ip="$2"; shift 2
mode="${APPLY_MODE:-apply}"

echo "${name}: boot-time config changed, rebooting"
[ "$mode" = "apply" ] || exit 0

cluster_healthy "$@"
wait_longhorn
talosctl -n "$ip" reboot --wait --timeout 30m
wait_ready "$name"
cluster_healthy "$@"
wait_longhorn
echo "${name}: rebooted, cluster healthy"
