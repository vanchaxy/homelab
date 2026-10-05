#!/usr/bin/env bash
# Write the generated configs (talosconfig, machine configs, router configs)
# from the state to ../output/ for use on the laptop. CI never writes them.
set -euo pipefail
cd "$(dirname "$0")"
install -d -m 700 ../output
tofu output -json files | python3 -c '
import json, os, sys
for name, content in json.load(sys.stdin).items():
    path = os.path.join("../output", name)
    fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(content)
    os.chmod(path, 0o600)
    print(path)
'
