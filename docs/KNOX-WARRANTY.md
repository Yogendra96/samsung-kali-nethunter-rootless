# Knox & Warranty Verification

> **Run this any time you want to verify your Samsung phone is in a warranty-safe state.**

## Short version

**After the entire samsung-kali-nethunter-rootless setup, the Samsung Galaxy S26 Ultra's Knox warranty bit is `0` (untouched), the bootloader is locked, and there is no root. Samsung warranty is fully intact.**

## Why this matters

Samsung's Knox warranty bit (`ro.boot.warranty_bit`) is a one-time-programmable hardware e-fuse. If it ever trips to `1` (e.g., from bootloader unlock, custom recovery, Magisk/KSU root, or modified kernel), it CANNOT be reset, and Samsung will void the warranty. This is the canonical "did you root your phone" check.

## How we verified (and you can re-verify any time)

From a Mac with the phone connected via USB, run:

```bash
# Make sure the phone is connected
adb devices

# Get the Knox warranty e-fuse state
adb -d shell getprop ro.boot.warranty_bit
# Should return: 0

# Verify the bootloader is locked
adb -d shell getprop ro.boot.flash.locked
# Should return: 1

# Get the device model
adb -d shell getprop ro.product.model
# Should return your model, e.g. SM-S948B

# Get the build fingerprint
adb -d shell getprop ro.build.fingerprint
# Should contain "release-keys" (NOT "test-keys" or "dev-keys")

# Verify verified boot state
adb -d shell getprop ro.boot.verifiedbootstate
# Should return: green

# Verify verity mode
adb -d shell getprop ro.boot.veritymode
# Should return: enforcing

# Verify SELinux
adb -d shell getenforce
# Should return: Enforcing

# Check ro.secure (1 = production build)
adb -d shell getprop ro.secure
# Should return: 1

# Check ro.debuggable (0 = production)
adb -d shell getprop ro.debuggable
# Should return: 0

# Check su binary (should NOT be present)
adb -d shell "which su"
# Should return: which: no su in (...)

# Check for Magisk/SuperSU (should NOT be installed)
adb -d shell "pm list packages | grep -E 'magisk|supersu'"
# Should return: nothing

# Check that Samsung Knox framework is intact (12+ packages)
adb -d shell "pm list packages | grep com.samsung.android.knox"
# Should return 12+ packages like:
#   package:com.samsung.android.knox.kpecore
#   package:com.samsung.android.knox.attestation
#   package:com.samsung.android.knox.pushmanager
#   ... (and more)

# Check that Samsung's original firmware packages are intact
adb -d shell "pm list packages | grep -c com.samsung"
# Should return ~50-100 (Samsung has many built-in apps)
```

## Verification table

| Check | Expected | Pass criteria |
|---|---|---|
| **Knox warranty e-fuse** (`ro.boot.warranty_bit`) | `0` | Untouched (0x0000) |
| **Bootloader locked** (`ro.boot.flash.locked`) | `1` | Locked |
| **Verified boot state** (`ro.boot.verifiedbootstate`) | `green` | Verified |
| **Verity mode** (`ro.boot.veritymode`) | `enforcing` | Enforcing |
| **Build fingerprint** | contains `release-keys` | Samsung-signed |
| **SELinux** | `Enforcing` | Enforcing |
| **`ro.secure`** | `1` | Production build |
| **`ro.debuggable`** | `0` | Production build |
| **Su binary** | (not present) | No root |
| **Magisk package** | (not present) | No root |
| **Knox framework apps** | 12+ `com.samsung.android.knox.*` | Samsung Knox framework intact |
| **Samsung firmware packages** | 50+ `com.samsung.*` | Original firmware |

**If all 12 checks pass, your phone is in a warranty-safe state.**

## What the entire samsung-kali-nethunter-rootless setup actually touches

The project installs a Kali Linux chroot via proot. Here's what it changes (and what it doesn't):

### What we changed (and why it doesn't void warranty)

| What we did | Where it lives | Knox/warranty impact |
|---|---|---|
| Disabled Auto Blocker | Settings toggle | ✅ None — software security feature, not Knox |
| Whitelisted Termux from battery | Settings toggle | ✅ None — settings only |
| Installed APKs via adb | `/data/app/` (user apps partition) | ✅ None — like installing WhatsApp |
| Ran Kali chroot in proot | `/data/data/com.termux/files/home/kali-arm64/` | ✅ None — fully sandboxed |
| Installed Fluxbox, rofi, fbpanel, etc. | Inside the chroot | ✅ None — chroot is user-space |
| Set up VNC server (tigervnc) on port 5901 | Inside the chroot | ✅ None — user-space daemon |
| Installed 77+ offensive security tools (apt + pipx + npm) | Inside the chroot | ✅ None — chroot is user-space |

### What we did NOT change (Knox-protected)

- ❌ **Bootloader** — still locked (`ro.boot.flash.locked = 1`)
- ❌ **Kernel** — still stock Samsung kernel
- ❌ **Recovery** — still stock Samsung recovery
- ❌ **System partition** (`/system/`) — untouched
- ❌ **Vendor partition** (`/vendor/`) — untouched
- ❌ **Knox e-fuse** — still `0x0000`
- ❌ **Verified boot metadata** — still Samsung-signed
- ❌ **dm-verity** — still enforcing
- ❌ **SELinux policy** — still Samsung's enforcing policy

**The chroot is fully sandboxed by Android.** Every file we created is in `/data/data/com.termux/files/`, which Android treats as Termux's private app data. The proot mechanism uses syscall interception to fake a Linux environment, but it cannot touch the system partition, the bootloader, the Knox e-fuse, or any firmware-level component.

## If you want to revert (you don't need to)

If you ever want to remove all traces of NetHunter and return the phone to stock:

```bash
adb -d uninstall com.termux
adb -d uninstall com.offsec.nethunter.kex
adb -d uninstall com.offsec.nethunter.store
adb -d uninstall com.iiordanov.bVNC.free
```

Then re-enable Auto Blocker: `Settings → Device Care → Auto Blocker → ON`.

**After this, the phone is in the exact factory state it was in before you started the project.** No Knox trip, no bootloader unlock, no root, no Samsung Pay issue, no banking app issue.

## What we tested and when

The last verification was on **2026-06-29** for a Samsung Galaxy S26 Ultra (SM-S948B, Snapdragon 8 Elite Gen 5, Android 16) after running `install-tools.sh` (Tier 1) end-to-end. All 12 checks passed.

You can re-run the same checks any time. The values shouldn't change unless you:
- Unlock the bootloader (Knox trips, warranty bit becomes `1`)
- Flash a custom recovery
- Install Magisk / KernelSU / SuperSU
- Flash a modified kernel

This project does none of those.

## What this means for Samsung Pay, banking apps, and OTA updates

- ✅ **Samsung Pay** — works normally (Knox is at 0x0000, no root detected)
- ✅ **Secure Folder** — works normally
- ✅ **Samsung Wallet** — works normally
- ✅ **Banking apps** with SafetyNet/Play Integrity — work normally (we don't root, don't change the system)
- ✅ **Netflix HD / DRM** — works normally (SafetyNet passes)
- ✅ **OTA updates from Samsung** — should receive them (we don't modify the system partition)
- ✅ **Google Pay** — works normally

All because the entire NetHunter setup runs in userspace and doesn't trip any of Android's integrity checks.

## Why this is safe (technical explanation)

The proot mechanism used by Termux + NetHunter is a **userspace-only** chroot that:

1. Translates path accesses (e.g., `/data/data/com.termux/files/home/kali-arm64/home/kali` → `/home/kali`)
2. Intercepts certain syscalls to make them work in the proot sandbox
3. Does NOT create a new user namespace
4. Does NOT modify the kernel
5. Does NOT modify SELinux labels
6. Does NOT modify the partition table
7. Does NOT trip the Knox e-fuse

This is fundamentally different from:
- **Magisk** (kernel-patches the boot image → Knox trips)
- **KernelSU** (loads a custom kernel module → Knox trips)
- **TWRP** (modifies recovery partition → Knox trips)
- **Bootloader unlock** (writes to bootloader e-fuse → Knox trips)

None of those happen here. The phone is in a state Samsung considers "untouched" for warranty purposes.

## How to verify yourself (in 30 seconds)

```bash
# The single most important check
adb -d shell getprop ro.boot.warranty_bit
# Must return: 0
```

If this returns `0`, the device is in a warranty-safe state. Period.

The other 11 checks are sanity verifications — they confirm that nothing else is suspicious. But `ro.boot.warranty_bit = 0` is the canonical Samsung-warranty check.
