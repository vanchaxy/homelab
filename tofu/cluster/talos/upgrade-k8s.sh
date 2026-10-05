#!/usr/bin/env bash
# Upgrade Kubernetes with talosctl upgrade-k8s (control plane and kubelets in
# the right order, bootstrap manifests synced, node configs updated by Talos).
#
#   upgrade-k8s.sh <version> <node-ip>      UPGRADE_MODE=apply | dry-run
set -euo pipefail

want="${1#v}"; node="$2"
mode="${UPGRADE_MODE:-apply}"

have=$(kubectl version -o json | python3 -c 'import json,sys;print(json.load(sys.stdin)["serverVersion"]["gitVersion"].lstrip("v"))')
if [ "$have" = "$want" ]; then echo "Kubernetes ${have}, nothing to do"; exit 0; fi
IFS=. read -r ma mi _ <<<"$have"; IFS=. read -r wa wi _ <<<"$want"
if [ "$wa" != "$ma" ] || [ $((wi - mi)) -gt 1 ] || [ $((wi - mi)) -lt 0 ]; then
  echo "refusing ${have} -> ${want}: Kubernetes must go one minor version at a time, never down"; exit 1
fi
echo "Kubernetes ${have} -> ${want}"
if [ "$mode" = "apply" ]; then
  talosctl -n "$node" upgrade-k8s --to "$want"
else
  talosctl -n "$node" upgrade-k8s --to "$want" --dry-run | tail -20
fi
