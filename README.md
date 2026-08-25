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

Version 0.4 introduces an app-first iOS workflow: Chameleon discovers third-party user applications, displays their original icons and bundle IDs, and creates or activates profiles directly from the selected app. System applications and jailbreak utility/tweak bundles are filtered out. Location selection uses an OpenStreetMap overlay with a tappable and draggable pin.

## Quick start

```sh
python3 tools/profilectl.py --root ./work/profiles profile create demo
python3 tools/profilectl.py --root ./work/profiles profile list

# Optional localhost daemon
python3 tools/daemon.py --root ./work/profiles
```

The daemon exposes `GET /profiles` and `POST /profiles` on loopback only.

## Download the latest GitHub build

With GitHub CLI authenticated, run:

```sh
./tools/download_latest_build.sh
```

The script downloads the newest successful `main` build and copies any `.deb`, `.ipa`, or `.zip` artifacts to `/home/whoareyou/Desktop/Githubbbbb`. Override the destination with `DEST=/some/folder ./tools/download_latest_build.sh`.
