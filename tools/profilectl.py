#!/usr/bin/env python3
"""Small, dependency-free profile manager used by the iOS companion/daemon."""
import argparse, hashlib, json, os, secrets, shutil, time
from pathlib import Path

SCHEMA = 1

def root_path(value):
    p = Path(value).expanduser().resolve(); p.mkdir(parents=True, exist_ok=True); return p

def read_db(root):
    p = root / "profiles.json"
    if not p.exists(): return {"schema": SCHEMA, "profiles": {}, "active": None}
    data = json.loads(p.read_text())
    if data.get("schema") != SCHEMA: raise SystemExit("Unsupported profile schema")
    return data

def write_db(root, data):
    tmp = root / "profiles.json.tmp"
    tmp.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n")
    os.replace(tmp, root / "profiles.json")

def profile_id(name):
    return hashlib.sha256((name + secrets.token_hex(8)).encode()).hexdigest()[:16]

def cmd_profile(args, root, db):
    if args.action == "list":
        for p in db["profiles"].values(): print(f"{p['id']}\t{p['name']}" + ("\tACTIVE" if p['id'] == db['active'] else ""))
    elif args.action == "create":
        if any(p["name"] == args.name for p in db["profiles"].values()): raise SystemExit("Profile already exists")
        pid = profile_id(args.name)
        db["profiles"][pid] = {"id": pid, "name": args.name, "apps": {}, "proxy": None, "location": None, "created": int(time.time())}
        write_db(root, db); print(pid)
    elif args.action == "activate":
        if args.profile not in db["profiles"]: raise SystemExit("Unknown profile id")
        db["active"] = args.profile; write_db(root, db); print(f"active={args.profile}")
    elif args.action == "set-proxy":
        p = db["profiles"].get(args.profile)
        if not p: raise SystemExit("Unknown profile id")
        p["proxy"] = {"scheme": args.scheme, "host": args.host, "port": args.port, "username": args.username}
        write_db(root, db)
    elif args.action == "set-location":
        p = db["profiles"].get(args.profile)
        if not p: raise SystemExit("Unknown profile id")
        p["location"] = {"latitude": args.latitude, "longitude": args.longitude, "label": args.label}
        write_db(root, db)
    elif args.action == "assign-app":
        p = db["profiles"].get(args.profile)
        if not p: raise SystemExit("Unknown profile id")
        p["apps"][args.bundle] = {"assigned": int(time.time()), "data_namespace": f"{p['id']}/{args.bundle}"}
        write_db(root, db)
    elif args.action == "remove-app":
        p = db["profiles"].get(args.profile)
        if not p: raise SystemExit("Unknown profile id")
        p["apps"].pop(args.bundle, None); write_db(root, db)
    elif args.action == "show":
        p = db["profiles"].get(args.profile)
        if not p: raise SystemExit("Unknown profile id")
        print(json.dumps(p, indent=2, sort_keys=True))

def cmd_backup(args, root, db):
    if args.action == "export":
        destination = Path(args.destination).expanduser().resolve()
        destination.parent.mkdir(parents=True, exist_ok=True)
        destination.write_text(json.dumps(db, indent=2, sort_keys=True) + "\n")
        print(destination)
    elif args.action == "import":
        source = Path(args.source).expanduser().resolve()
        incoming = json.loads(source.read_text())
        if incoming.get("schema") != SCHEMA or not isinstance(incoming.get("profiles"), dict): raise SystemExit("Invalid backup")
        write_db(root, incoming); print(f"imported={len(incoming['profiles'])}")

def main():
    ap = argparse.ArgumentParser(); ap.add_argument("--root", default="./profiles")
    sub = ap.add_subparsers(dest="group", required=True); pp = sub.add_parser("profile"); ps = pp.add_subparsers(dest="action", required=True)
    ps.add_parser("list"); c=ps.add_parser("create"); c.add_argument("name")
    a=ps.add_parser("activate"); a.add_argument("profile")
    s=ps.add_parser("show"); s.add_argument("profile")
    q=ps.add_parser("assign-app"); q.add_argument("profile"); q.add_argument("bundle")
    q=ps.add_parser("remove-app"); q.add_argument("profile"); q.add_argument("bundle")
    x=ps.add_parser("set-proxy"); x.add_argument("profile"); x.add_argument("scheme", choices=["http","https","socks5"]); x.add_argument("host"); x.add_argument("port", type=int); x.add_argument("--username")
    l=ps.add_parser("set-location"); l.add_argument("profile"); l.add_argument("latitude", type=float); l.add_argument("longitude", type=float); l.add_argument("--label", default="")
    bp=sub.add_parser("backup"); bs=bp.add_subparsers(dest="action", required=True); e=bs.add_parser("export"); e.add_argument("destination"); i=bs.add_parser("import"); i.add_argument("source")
    args=ap.parse_args(); root=root_path(args.root); db=read_db(root)
    if args.group == "profile": cmd_profile(args, root, db)
    elif args.group == "backup": cmd_backup(args, root, db)

if __name__ == "__main__": main()
