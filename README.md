# Google Camera Systemizer

A Magisk / KernelSU / APatch module that mounts Google Camera as a system app, so
other apps can resolve and call its camera intents:

- `android.media.action.IMAGE_CAPTURE`
- `android.media.action.STILL_IMAGE_CAMERA`
- `android.media.action.VIDEO_CAPTURE`
- the secure variants (`_SECURE`)

The module copies the Google Camera install from *your* phone. No Google APK is
distributed with this repository.

## Why

Some apps call the system camera through an intent and pick a provider themselves.
When Google Camera is only a user app, those intents can resolve to the stock
camera, or to nothing at all. With the package flagged `SYSTEM`, the intent
resolves to Google Camera and the stock camera can stay disabled.

## Requirements

- Rooted phone with Magisk 20.4 or newer (Zygisk not required), KernelSU, or APatch.
- Google Camera installed as a normal user app.
- `adb` and `bash` on the computer used for the build.

## Build

The build reads the live install on the connected phone, so the result always
matches the camera version on that phone.

```sh
git clone https://github.com/aaronmurniadi/gcam-systemizer.git
cd gcam-systemizer
./build.sh
```

Output: `dist/GoogleCamera-Systemizer-<version>.zip`.

Two phones attached? Select one:

```sh
ANDROID_SERIAL=<serial> ./build.sh
```

`adb devices -l` prints the serials.

The script does three things: copy the base APK and every split from
`/data/app/.../com.google.android.GoogleCamera-*`, write the version into
`module/module.prop`, and zip the module.

Run the build again after a Google Camera update. The module holds a frozen copy,
so a Play Store update makes it stale.

## Install

Magisk / KernelSU / APatch app: **Modules → Install from storage**, pick the zip,
reboot.

Or over adb:

```sh
adb push dist/GoogleCamera-Systemizer-<version>.zip /sdcard/Download/gcam.zip
adb shell "su -c 'magisk --install-module /sdcard/Download/gcam.zip'"
adb reboot
```

## Verify

```sh
adb shell dumpsys package com.google.android.GoogleCamera | grep -m1 pkgFlags
adb shell pm list packages -s | grep GoogleCamera
adb shell cmd package resolve-activity --brief -a android.media.action.IMAGE_CAPTURE
```

`pkgFlags` must contain `SYSTEM`. The last command must name Google Camera.

Optional: make Google Camera the default camera app.

- Settings → Apps → Default apps → Camera → Google Camera, or
- `adb shell "su -c 'cmd role add-role-holder android.app.role.CAMERA com.google.android.GoogleCamera'"`

## How it works

- The module magic-mounts the APKs into `/system/priv-app/GoogleCamera/`.
- PackageManager scans that directory at boot. Google Camera gains the `SYSTEM`
  flag and privileged-app status.
- The copy in `/data/app` carries the same version, so PackageManager treats it as
  the update of the system app. App data, settings, and permissions are untouched.
- `customize.sh` adds `privapp-permissions-gcam.xml` with `BIND_WALLPAPER` only
  when the ROM does not already declare the package.

### About the `PRIVILEGED` flag

The module sets up a privileged location but ships no blanket permission
allowlist. If the ROM enforces `ro.control_privapp_permissions=enforce`, add the
permissions Google Camera requests to
`module/system/etc/permissions/privapp-permissions-gcam.xml` before building.
Without that, the app still runs and camera intents still resolve.

## Remove

Delete the module in the root manager app, or:

```sh
adb shell "su -c 'touch /data/adb/modules/gcam_systemizer/disable'"
```

Reboot. Google Camera becomes a normal user app again, and app data is kept.

If the phone does not boot with the module enabled:

```sh
adb shell "su -c 'rm -rf /data/adb/modules/gcam_systemizer'"
adb reboot
```

## Layout

| Path | Purpose |
|---|---|
| `build.sh` | Copies the APKs from the phone and builds the zip |
| `module/module.prop` | Module identity, written by the build |
| `module/customize.sh` | Installer: sets permissions, optional allowlist |
| `module/system/priv-app/GoogleCamera/` | Mount point, filled by the build, ignored by git |
| `dist/` | Build output, ignored by git |

## License

MIT. See [LICENSE](LICENSE).
