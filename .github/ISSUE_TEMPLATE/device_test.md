---
name: 📱 Device test report
about: Report success/failure on a specific device
title: "[TEST] <device model>: <pass/fail>"
labels: ["device-test"]
assignees: []
---

Thanks for testing on a new device! Please fill in the form below so we can add it to the supported devices list.

## Device info

- **Manufacturer:** (e.g. Samsung, OnePlus, Google, Xiaomi)
- **Model:** (e.g. Galaxy A55, OnePlus 13, Pixel 9 Pro)
- **Model number:** (e.g. SM-A556B, CPH2649, GEC77)
- **SoC:** (e.g. Snapdragon 8 Gen 3, Exynos 1480, Tensor G4)
- **Android version:** (e.g. Android 15)
- **UI version:** (e.g. One UI 7, OxygenOS 15, stock)
- **Storage available:** (run `adb shell df -h /data`)

## Test result

- [ ] ✅ **Full success** — install completed, all 30+ tools work, desktop launches, VNC connects
- [ ] 🟡 **Partial success** — install worked but some tools/features don't
- [ ] ❌ **Failure** — install failed at some step

## What worked

- (e.g. "Bootstrap completed, postgresql fix worked, all 30+ tools installed")

## What didn't work

- (e.g. "xfce4-panel crashed, had to use Fluxbox" or "Auto Blocker not off, had to disable manually")

## Specific commands that worked/failed

```bash
# Paste the actual output of these commands
adb shell getprop ro.boot.warranty_bit
adb shell getprop ro.build.fingerprint
cat /etc/os-release | grep PRETTY  # inside the chroot
which nmap msfconsole burpsuite   # inside the chroot
```

## Screenshots

If possible, attach a screenshot of:
- The Fluxbox desktop running
- `nethunter` dropping you into the chroot
- `msfconsole` loading (or a simple nmap scan)
- A `apt list --installed | wc -l` showing the chroot has lots of packages

## Anything else?

- (e.g. "Auto Blocker was on by default, needed to disable" or "Battery whitelist needed for Termux")

## Will you be willing to maintain this device's notes in the docs?

- [ ] Yes — I'll update docs/SAMSUNG.md (or add docs/ONEPLUS.md, docs/PIXEL.md) with device-specific notes
- [ ] No — just reporting the test result

## Checklist

- [ ] I ran the full install.sh end-to-end
- [ ] I verified Knox e-fuse is still 0x0000 (`adb shell getprop ro.boot.warranty_bit`)
- [ ] I verified at least nmap and one other tool work
- [ ] I tested the VNC desktop
