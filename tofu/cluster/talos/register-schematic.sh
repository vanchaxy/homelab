#!/usr/bin/env bash
# Register the image schematic with factory.talos.dev, so that the installer
# and ISO URLs built from its ID (the sha256 of the canonical YAML) resolve.
#
#   SCHEMATIC=<canonical yaml> SCHEMATIC_ID=<sha256> register-schematic.sh
#
# The factory often times out TLS handshakes from GitHub's runners, so a
# failure only warns: registering once from anywhere is enough, and a node
# pulling an unregistered installer fails loudly anyway. Run it by hand from
# the laptop if CI warned.
set -euo pipefail

got=$(curl -fsS --retry 5 --retry-all-errors --retry-delay 5 --max-time 30 \
  -X POST --data-binary "$SCHEMATIC" https://factory.talos.dev/schematics || true)
case "$got" in
  *"\"id\":\"${SCHEMATIC_ID}\""*) echo "schematic ${SCHEMATIC_ID} registered" ;;
  "") echo "warning: could not reach factory.talos.dev; register schematic ${SCHEMATIC_ID} from the laptop" >&2 ;;
  *) echo "factory.talos.dev returned a different schematic ID than computed: ${got}" >&2; exit 1 ;;
esac
