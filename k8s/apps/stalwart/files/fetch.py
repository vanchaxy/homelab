import email.parser
import email.utils
import imaplib
import json
import logging
import os
import re
import smtplib
import ssl
import sys
import threading
import time

STATE_DIR = os.environ.get("FETCH_STATE_DIR", "/var/lib/stalwart/fetch")
SOURCES = os.environ.get("FETCH_SOURCES", "/config/sources")
LMTP_HOST = os.environ.get("LMTP_HOST", "127.0.0.1")
LMTP_PORT = int(os.environ.get("LMTP_PORT", "24"))
IDLE_SECONDS = int(os.environ.get("FETCH_IDLE_SECONDS", str(25 * 60)))
RETRY_SECONDS = int(os.environ.get("FETCH_RETRY_SECONDS", "30"))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s [%(threadName)s] %(message)s", stream=sys.stdout)
log = logging.getLogger("fetch")


class Source:
    def __init__(self, name, server, prefix, target):
        self.name = name
        self.server = server
        self.user = os.environ[f"{prefix}_USER"]
        self.password = os.environ[f"{prefix}_PASSWORD"]
        self.target = target
        self.state_path = os.path.join(STATE_DIR, f"{name}.json")

    def load_state(self):
        try:
            with open(self.state_path) as f:
                return json.load(f)
        except FileNotFoundError:
            return None

    def save_state(self, uidvalidity, last_uid):
        tmp = f"{self.state_path}.tmp"
        with open(tmp, "w") as f:
            json.dump({"uidvalidity": uidvalidity, "last_uid": last_uid}, f)
        os.replace(tmp, self.state_path)


def envelope_sender(raw):
    headers = email.parser.BytesHeaderParser().parsebytes(raw)
    _, addr = email.utils.parseaddr(headers.get("Return-Path", ""))
    return addr


def deliver(raw, target):
    with smtplib.LMTP(LMTP_HOST, LMTP_PORT) as lmtp:
        refused = lmtp.sendmail(envelope_sender(raw), [target], raw)
    if refused:
        raise RuntimeError(f"LMTP refused {target}: {refused}")


def status_value(imap, item):
    typ, data = imap.status("INBOX", f"({item})")
    if typ != "OK":
        raise RuntimeError(f"STATUS {item} failed: {data}")
    match = re.search(rf"{item} (\d+)".encode(), data[0])
    return int(match.group(1))


def new_uids(imap, last_uid):
    typ, data = imap.uid("SEARCH", None, f"UID {last_uid + 1}:*")
    if typ != "OK":
        raise RuntimeError(f"UID SEARCH failed: {data}")
    return sorted(uid for uid in map(int, data[0].split()) if uid > last_uid)


def sync(source, imap, uidvalidity, last_uid):
    for uid in new_uids(imap, last_uid):
        typ, data = imap.uid("FETCH", str(uid), "(BODY.PEEK[])")
        parts = [p for p in data if isinstance(p, tuple)]
        if typ != "OK" or not parts:
            raise RuntimeError(f"UID FETCH {uid} failed: {data}")
        deliver(parts[0][1], source.target)
        last_uid = uid
        source.save_state(uidvalidity, last_uid)
        log.info("delivered uid %d to %s", uid, source.target)
    return last_uid


def session(source):
    context = ssl.create_default_context()
    with imaplib.IMAP4_SSL(source.server, 993, ssl_context=context, timeout=IDLE_SECONDS + 120) as imap:
        imap.login(source.user, source.password)
        uidvalidity = status_value(imap, "UIDVALIDITY")
        state = source.load_state()
        if state is None or state["uidvalidity"] != uidvalidity:
            last_uid = status_value(imap, "UIDNEXT") - 1
            source.save_state(uidvalidity, last_uid)
            log.info("starting from uid %d (uidvalidity %d)", last_uid, uidvalidity)
        else:
            last_uid = state["last_uid"]
        imap.select("INBOX", readonly=True)
        while True:
            last_uid = sync(source, imap, uidvalidity, last_uid)
            with imap.idle(duration=IDLE_SECONDS) as idler:
                for typ, _ in idler:
                    if typ == "EXISTS":
                        break


def run(source):
    while True:
        try:
            session(source)
        except Exception as e:
            log.warning("session ended: %s", e)
        time.sleep(RETRY_SECONDS)


def main():
    os.makedirs(STATE_DIR, exist_ok=True)
    threads = []
    with open(SOURCES) as f:
        for line in f:
            if not line.strip():
                continue
            source = Source(*line.strip().split("|"))
            thread = threading.Thread(target=run, args=(source,), name=source.name, daemon=True)
            thread.start()
            threads.append(thread)
    for thread in threads:
        thread.join()


if __name__ == "__main__":
    main()
