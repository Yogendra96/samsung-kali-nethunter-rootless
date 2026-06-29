---
name: 🐛 Bug report
about: Something isn't working
title: "[BUG] "
labels: ["bug", "needs-triage"]
assignees: []
---

## Describe the bug

A clear and concise description of what the bug is.

## Steps to reproduce

1. Run command `...`
2. Click on `...`
3. See error

## Expected behavior

A clear and concise description of what you expected to happen.

## Actual behavior

What actually happened. Include the full error message and stack trace if applicable.

## Environment

**Phone:**
- Model: (e.g. Samsung Galaxy S26 Ultra, SM-S948B)
- Android version: (e.g. Android 16)
- One UI version (Samsung only): (e.g. One UI 8.0)
- Knox e-fuse state: (run `adb shell getprop ro.boot.warranty_bit`)
- Available storage: (run `adb shell df -h /data`)
- Auto Blocker: (On/Off)

**Mac:**
- macOS version: (e.g. macOS 15.4)
- adb version: (run `adb --version`)
- scrcpy version: (run `scrcpy --version`)
- Homebrew: (Yes/No)

**Kali chroot:**
- Kali version: (run `cat /etc/os-release` inside the chroot)
- nethunter installer version: (run `cat install-nethunter-termux | head -5` — should say `VERSION=20250525`)
- Installed tools that work/fail: (run `which nmap msfconsole burpsuite` inside the chroot)

## Relevant log output

```
[paste the output of the failing command here]
```

## Screenshots

If applicable, add screenshots to help explain the problem.

## Additional context

Any other relevant information (recently changed settings, related issues, etc.)

## Checklist

- [ ] I searched [existing issues](https://github.com/Yogendra96/samsung-kali-nethunter-rootless/issues) to make sure this isn't a duplicate
- [ ] I read [TROUBLESHOOTING.md](https://github.com/Yogendra96/samsung-kali-nethunter-rootless/blob/main/docs/TROUBLESHOOTING.md) and tried the suggested fixes
- [ ] I can reproduce this bug on a clean install (wipe the chroot and re-run install.sh)
