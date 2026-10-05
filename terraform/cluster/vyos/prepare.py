# Runs on the router (as root) before the config apply. Reads the file bundle as
# JSON on stdin, writes changed files (seed_only files only when missing), derives
# the login hash, creates container volume directories and pulls container images.
import json, os, re, subprocess, sys

mode = sys.argv[1]  # apply | dry-run
desired = open("/config/tofu/desired.sh").read()
bundle = json.load(sys.stdin)
changed = []

for path, f in sorted(bundle.items()):
    content = f["content"]
    exists = os.path.exists(path)
    if f.get("seed_only") and exists:
        continue
    if exists and open(path).read() == content:
        continue
    changed.append(path)
    if mode == "apply":
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            fh.write(content)
        os.chmod(path, int(f["mode"], 8))
        if path.startswith("/config/auth/"):
            subprocess.run(["chown", "vyos:users", path], check=True)

pw, salt = "/config/auth/login-password.vyos", "/config/auth/login-salt.vyos"
if os.path.exists(pw) and os.path.exists(salt) and mode == "apply":
    h = subprocess.run(["openssl", "passwd", "-6", "-salt", open(salt).read().strip(), open(pw).read().strip()],
                       capture_output=True, text=True, check=True).stdout.strip()
    hp = "/config/auth/login-hash.vyos"
    if not os.path.exists(hp) or open(hp).read() != h:
        changed.append(hp)
        open(hp, "w").write(h)
        os.chmod(hp, 0o600)
        subprocess.run(["chown", "vyos:users", hp], check=True)

for src in re.findall(r"set container name \S+ volume \S+ source '([^']+)'", desired):
    if not os.path.exists(src) and not os.path.splitext(src)[1] and not src.startswith("/run/"):
        changed.append(src + "/")
        if mode == "apply":
            os.makedirs(src, exist_ok=True)

for image in sorted(set(re.findall(r"set container name \S+ image '([^']+)'", desired))):
    if subprocess.run(["podman", "image", "exists", image]).returncode != 0:
        changed.append("image " + image)
        if mode == "apply":
            subprocess.run(["podman", "pull", "-q", image], check=True, stdout=subprocess.DEVNULL)

print("prepare (%s): %s" % (mode, ", ".join(changed) if changed else "nothing to change"))
