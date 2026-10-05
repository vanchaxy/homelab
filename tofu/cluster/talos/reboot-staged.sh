#!/usr/bin/env bash
# Reboot the nodes whose new machine config was staged because it needs a
# reboot (talos_machine_configuration_apply with staged_if_needing_reboot),
# strictly one node at a time.
#
#   reboot-staged.sh <name=ip=resolved-apply-mode>...   APPLY_MODE=apply | dry-run
#
# Per staged node: check the cluster is healthy and Longhorn has no degraded
# volumes; reboot, which boots into the staged config; wait for Ready, etcd and
# Longhorn again. Any failure stops the loop.
# No drain: Talos stops all pods gracefully before a reboot and the node is
# back within minutes (siderolabs/talos#9603).
set -euo pipefail
. "$(dirname "$0")/node-lib.sh"

mode="${APPLY_MODE:-apply}"

ips=(); for t in "$@"; do r="${t#*=}"; ips+=("${r%%=*}"); done
for t in "$@"; do
  name="${t%%=*}"; r="${t#*=}"; ip="${r%%=*}"; resolved="${r#*=}"
  if [ "$resolved" != "staged" ]; then echo "${name}: config applied live, no reboot"; continue; fi
  echo "${name}: config staged, rebooting"
  [ "$mode" = "apply" ] || continue

  cluster_healthy "${ips[@]}"
  wait_longhorn
  talosctl -n "$ip" reboot --wait --timeout 30m
  wait_ready "$name"
  cluster_healthy "${ips[@]}"
  wait_longhorn
  echo "${name}: rebooted into the staged config, cluster healthy"
done
