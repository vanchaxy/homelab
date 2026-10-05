# Shared helpers for upgrade-talos.sh and reboot-staged.sh; source, don't run.
longhorn_timeout="${LONGHORN_WAIT_TIMEOUT:-5400}"

talos_version() { talosctl -n "$1" version 2>/dev/null | awk '/Server:/{s=1} s && /Tag:/{print $2; exit}'; }

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

wait_ready() {
  local deadline=$(( $(date +%s) + 900 ))
  until kubectl get node "$1" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null | grep -qx True; do
    [ "$(date +%s)" -lt "$deadline" ] || { echo "$1 not Ready after 900s"; return 1; }
    sleep 10
  done
}
