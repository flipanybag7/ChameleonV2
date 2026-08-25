# Rootless iOS Profile Manager (iPhone 7 / iOS 15.8)

This repository contains the safe, test-oriented foundation for a palera1n rootless profile manager.

The rootless package targets iOS 15+ and supports both palera1n and Dopamine environments through ElleKit/Substrate-compatible tweak loading.

## Scope

- Persistent app-profile metadata and assignments
- Proxy configuration and connectivity checks
- Location profiles for authorised testing
- Encrypted backup/import
- Local CLI and daemon API foundation
- Diagnostics and consistency validation

The project does not implement jailbreak-detection bypass, anti-detection evasion, or modem-level IMEI/serial manipulation.

## Current status

The first milestone is a platform-neutral profile store and CLI. The iOS package and injected app-data adapter must be built and tested on macOS with the matching Theos/palera1n toolchain.

## Quick start

```sh
python3 tools/profilectl.py --root ./work/profiles profile create demo
python3 tools/profilectl.py --root ./work/profiles profile list

# Optional localhost daemon
python3 tools/daemon.py --root ./work/profiles
```

The daemon exposes `GET /profiles` and `POST /profiles` on loopback only.
