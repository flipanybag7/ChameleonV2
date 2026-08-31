# Rootless iOS Profile Manager (iPhone 7 / iOS 15.8)

This repository contains the safe, test-oriented foundation for a palera1n rootless profile manager.

The rootless package targets iOS 15+ and supports both palera1n and Dopamine environments through ElleKit/Substrate-compatible tweak loading.

## Scope

- Persistent app-profile metadata and assignments
- Per-profile proxy routing for standard `NSURLSession` configurations
- Native MapKit location profiles and app-scoped Core Location overrides
- JSON backup/export and validated import
- Local CLI and daemon API foundation
- Diagnostics and consistency validation

The project does not implement jailbreak-detection bypass, anti-detection evasion, or modem-level IMEI/serial manipulation.

## Current status

Version 1.0.2 uses an overview-first workflow. The dashboard shows only the currently running profile; installed applications live in a separate Applications screen, and every application opens its own list of profiles. Each profile has a dedicated setup page for activation, launch, device identity, proxy, location and editable profile metadata aliases. System applications and jailbreak utility/tweak bundles are filtered out. The location picker bundles Leaflet locally, uses OpenStreetMap tiles, and provides native search plus a tappable/draggable pin. Saving a pin persists its coordinates and enables the location profile automatically.

The device catalog includes coherent presets from iPhone 7 through iPhone 15 Pro Max, including Plus, X, XR, XS, mini, Pro, Pro Max, and second/third-generation SE variants.

Proxy routing and location overrides are loaded only inside the selected user application. Proxy routing covers standard default, ephemeral, and background `NSURLSessionConfiguration` instances; applications using custom socket stacks can bypass it. Core Location overrides apply to `CLLocation` objects delivered in the selected process.

The Settings screen exposes backup export/import, runtime diagnostics, active-profile fixture inspection, and explicit isolation boundaries.
It also includes a read-only Device Identifiers section for the local serial,
IMEI, MEID, and Wi-Fi MAC when those values are available to the jailbreak app.
These values are displayed in memory only and are not written to profiles or backups.

## Quick start

```sh
python3 tools/profilectl.py --root ./work/profiles profile create demo
python3 tools/profilectl.py --root ./work/profiles profile list

# Optional localhost daemon
python3 tools/daemon.py --root ./work/profiles
```

The daemon exposes `GET /profiles` and `POST /profiles` on loopback only.

## Per-app device profiles

Every app profile contains a versioned local device-identity record. The
runtime loads it only when the profile is active and the current user app is
assigned to that profile. Other applications and system processes retain their
normal values.

The runtime currently overrides these standard app-visible surfaces:

- `UIDevice` model, localized model, system version, and IDFV
- `sysctlbyname` values for `hw.machine`, `hw.model`, and `hw.memsize`
- `NSProcessInfo` operating-system version and physical memory
- `UIScreen` bounds, native bounds, scale, and native scale
- `NSLocale`, preferred language, region, and `NSTimeZone`
- `CTCarrier` carrier name, MCC, MNC, and ISO country code

IDFV values are deterministically derived from the profile seed and bundle ID,
so two apps assigned to the same profile still receive different UUIDs. Empty
fields fall through to the real API value.

The profile also stores PPI, serial-number, IMEI, MEID, and Wi-Fi MAC test
fixtures. These values remain part of the local profile and backup, but do not
rewrite the device's hardware, modem, baseband, or network interface.

Profile consistency checks validate UUID, display, memory, carrier, timezone,
IMEI, and MEID field formatting before launch. Changes take effect when the
target application is relaunched.

## App data containers

`ProfileRuntime` includes a filesystem container for the injected application.
New and migrated profiles enable container separation by default. Common
pathname operations—including `open`, `openat`, `fopen`,
`freopen`, `stat`, `lstat`, `fstatat`, `access`, `unlink`, `rename`, `mkdir`,
`rmdir`, `opendir`, `readlink`, and `chmod`—that target the app's sandbox are
redirected to:

```text
<app-home>/Library/Chameleon/Containers/<bundle-id>/<profile-id>/<container-id>/...
```

The tree stays inside the application's writable sandbox. The active profile
and active container IDs are included in the path, so each
container receives a separate tree even when it belongs to the same app profile.
The hook is enabled only for the user application assigned to Chameleon's
currently active profile; SpringBoard, Chameleon itself, and unrelated apps
are left unchanged.

Bundle resources and paths outside the app sandbox are not redirected. The
container is provisioned automatically before the runtime hooks are installed.
Standard `NSUserDefaults` also uses a profile-specific suite, and Chameleon
terminates a running target before opening the newly selected profile.

This is pathname interposition, not a kernel sandbox. Relative `openat` calls
against an already-open directory, direct syscalls, memory-mapped files, and
file descriptors opened through unhandled APIs retain normal kernel behavior.
Symlinks inside the source tree should be treated as an escape unless the
container is provisioned with equivalent symlinks.

Keychain records, shared App Group containers, extension processes, and storage
owned by separate WebKit or service processes are not isolated. Consequently,
this layer must not be described as a complete clone of an arbitrary third-party
application or as creating a fresh account session.

## Download the latest GitHub build

With GitHub CLI authenticated, run:

```sh
./tools/download_latest_build.sh
```

The script downloads the newest successful `main` build and copies any `.deb`, `.ipa`, or `.zip` artifacts to `/home/whoareyou/Desktop/Githubbbbb`. Override the destination with `DEST=/some/folder ./tools/download_latest_build.sh`.
