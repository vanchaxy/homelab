import base64
import json
import os
import sys
import urllib.parse
import urllib.request

BASE = os.environ["STALWART_URL"].rstrip("/")
ADMIN = os.environ.get("STALWART_USER", "admin")
PASSWORD = os.environ["STALWART_PASSWORD"]
SCRIPT_NAME = os.environ.get("SIEVE_SCRIPT_NAME", "inbound")
SCRIPT_PATH = os.environ.get("SIEVE_SCRIPT_PATH", "/sieve/inbound.sieve")
ACCOUNTS = os.environ["SIEVE_ACCOUNTS"].split()
USING = ["urn:ietf:params:jmap:core", "urn:ietf:params:jmap:sieve"]


def rebase(url):
    parsed = urllib.parse.urlsplit(url)
    return BASE + parsed.path + (f"?{parsed.query}" if parsed.query else "")


def request(auth, url, data=None, content_type="application/json"):
    req = urllib.request.Request(url, data=data, method="POST" if data is not None else "GET")
    req.add_header("Authorization", f"Basic {auth}")
    req.add_header("X-Forwarded-For", "127.0.0.1")
    if data is not None:
        req.add_header("Content-Type", content_type)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def install(account, script):
    auth = base64.b64encode(f"{account}%{ADMIN}:{PASSWORD}".encode()).decode()
    session = request(auth, f"{BASE}/jmap/session")
    account_id = session["primaryAccounts"]["urn:ietf:params:jmap:sieve"]
    api_url = rebase(session["apiUrl"])
    upload_url = rebase(session["uploadUrl"].replace("{accountId}", account_id))

    blob_id = request(auth, upload_url, script, "application/sieve")["blobId"]

    def call(method, args):
        body = json.dumps({"using": USING, "methodCalls": [[method, {"accountId": account_id, **args}, "0"]]})
        name, result, _ = request(auth, api_url, body.encode())["methodResponses"][0]
        if name == "error":
            raise RuntimeError(f"{method}: {result}")
        return result

    existing = call("SieveScript/query", {"filter": {"name": SCRIPT_NAME}})["ids"]
    if existing:
        args = {"update": {existing[0]: {"blobId": blob_id}}, "onSuccessActivateScript": existing[0]}
    else:
        args = {"create": {"s": {"name": SCRIPT_NAME, "blobId": blob_id}}, "onSuccessActivateScript": "#s"}
    result = call("SieveScript/set", args)
    failures = {k: v for k, v in result.items() if k.startswith("not") and v}
    if failures:
        raise RuntimeError(f"SieveScript/set for {account}: {failures}")
    print(f"installed sieve script {SCRIPT_NAME!r} for {account}")


def main():
    with open(SCRIPT_PATH, "rb") as f:
        script = f.read()
    for account in ACCOUNTS:
        install(account, script)


if __name__ == "__main__":
    sys.exit(main())
