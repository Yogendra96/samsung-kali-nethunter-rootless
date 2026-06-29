# samsung-kali-nethunter-rootless

> **Run Kali Linux + full offensive security tools on a stock Samsung Galaxy phone.**
> **No root. No bootloader unlock. No Knox trip. No warranty void.**

Tested on **Samsung Galaxy S26 Ultra (SM-S948B, Snapdragon 8 Elite Gen 5, Android 16)**.
Also works on any Android 13+ device with Termux (OnePlus, Pixel, etc.).

---

## What is this?

This project automates the setup of **Kali NetHunter Rootless** on a Samsung Galaxy phone using:

- **Termux** — the Android terminal emulator
- **proot** — a userspace chroot (no kernel features needed)
- **Kali Linux chroot** — the full Kali filesystem (~2.5 GB)
- **Fluxbox + xfce4-terminal** — a graphical desktop inside the chroot
- **tigervnc + NetHunter KeX app** — the VNC server + client

The chroot runs in userspace, sandboxed by Android the same way WhatsApp or any other app is. **It does not touch the system partition, does not unlock the bootloader, does not modify Knox, and does not void your Samsung warranty.**

---

## What's included

The installer sets up a working Kali Linux environment with:

- **1,800+ Kali packages** (full chroot)
- **Offensive security tools:** nmap, msfconsole, sqlmap, aircrack-ng, wireshark, burpsuite, ffuf, gobuster, nikto, john, hydra, hashcat, responder, seclists, dirb, ncrack, wpscan, enum4linux, ldap-utils, smbclient, nbtscan, snmp, autopsy, sleuthkit, tcpdump, etc.
- **Fluxbox graphical desktop** (the only DE that works in proot on 2026 devices — see "Why Fluxbox, not XFCE" below)
- **System tools:** fbpanel (taskbar), stalonetray (system tray), conky (system info), rofi (app launcher), pcmanfm (file manager), feh (wallpaper), notification-daemon
- **sshd** so you can ssh from your Mac into the chroot

---

## Quick start (3 commands)

On your Mac, with the phone connected via USB:

```bash
# 1. Install adb + scrcpy on the Mac
brew install android-platform-tools scrcpy

# 2. Install Termux and NetHunter Store on the phone
# (download the APKs from F-Droid and store.nethunter.com first, or use the URLs)
adb -d install termux.apk
adb -d install NetHunterStore.apk
```

Then on the phone, in **Termux** (not the Mac terminal):

```bash
# 3. One-liner install (in Termux)
wget -qO install.sh https://raw.githubusercontent.com/YOUR-USERNAME/samsung-kali-nethunter-rootless/main/install.sh
bash install.sh
```

That's it. After ~25 minutes, the chroot is set up with the full Kali toolset and the Fluxbox desktop.

---

## Manual install (if you prefer to see what's happening)

### On the phone (in Termux):

```bash
pkg update -y && pkg install -y wget
wget -O install-nethunter-termux https://offs.ec/2MceZWr
chmod +x install-nethunter-termux
./install-nethunter-termux          # choose 'full'
```

### Drop into the chroot:

```bash
nethunter -r        # as root
```

### From inside the chroot, run the chroot-side installer:

```bash
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/samsung-kali-nethunter-rootless/main/install.sh | bash
```

### Start the desktop:

```bash
# Back in Termux:
nethunter kex &amp;       # start VNC server
# Open NetHunter KeX app on phone → enter password → see desktop
```

---

## Controlling the phone from your Mac

Use the companion `control-from-mac.sh` script:

```bash
# On the Mac:
./control-from-mac.sh
```

This gives you a menu of:
1. **scrcpy** — mirror the phone screen to your Mac, with full keyboard/mouse control
2. **adb shell** — terminal access to the phone
3. **Send text** — type into the focused app on the phone from the Mac
4. **TCP ADB** — set up wireless ADB so you can unplug the USB cable
5. **Take screenshots**
6. **Install APKs** from your Mac to the phone
7. **Push/pull files** between Mac and phone

### scrcpy keyboard shortcuts (when scrcpy window is focused):

| Shortcut | Action |
|---|---|
| `Cmd+S` | Toggle fullscreen |
| `Cmd+H` | Toggle hide mouse cursor |
| `Cmd+P` | Toggle power button (lock/unlock) |
| `Cmd+B` | Toggle back button |
| `Cmd+M` | Toggle menu button |
| `Cmd+O` | Turn phone screen off (saves battery) |
| `Cmd+Shift+O` | Turn phone screen back on |
| `Right-click` | Android back button |
| Drag & drop | Copy files from Mac to phone |

---

## Why Fluxbox, not XFCE/MATE/GNOME?

The official NetHunter Rootless docs (from 2024) recommend XFCE. **That doesn't work on 2026 Android devices.** Why?

The crash chain is:

1. `xfce4-session` starts
2. It launches `xfwm4` (the window manager) which uses gdk-pixbuf
3. Modern gdk-pixbuf delegates SVG loading to **glycin-loaders** (a separate sandboxed process)
4. glycin-loaders use **`bwrap` (bubblewrap)** with `--unshare-all` to sandbox the loader
5. `bwrap --unshare-all` requires **Linux user namespaces** which **proot cannot fake**
6. `bwrap` exits with error → gdk-pixbuf fails → GTK apps crash → session aborts

The visible errors are:
- `xfce4-session: ... ComparingUpdateTracker: 0 pixels in / 0 pixels out, (1:nan ratio) Aborted`
- `xfsessiond: ICE I/O Error, Disconnected from session manager`
- `GLib-GIO-ERROR: Settings schema 'org.mate.session' is not installed`
- `libEGL warning: DRI3 error: Could not get DRI3 device`

**Fluxbox is the only DE that works** because it doesn't use gdk-pixbuf or bwrap. It's also lightweight (~50 KB) and works with fbpanel + stalonetray + rofi to give a real desktop feel.

The proot upstream has a fix in master ([termux/proot#359](https://github.com/termux/proot/pull/359), merged 2026-06-01) but it's not in a Termux release yet. When `pkg update && pkg upgrade proot` ships a newer version, XFCE may work again — but for now, Fluxbox is the canonical answer.

---

## What's the difference between this and other projects?

| | jorexdeveloper/termux-nethunter | xiv3r/Kali-Linux-Termux | EXALAB/AnLinux-App | **This project** |
|---|---|---|---|---|
| Stars | 265 | 307 | 2236 | (new) |
| Last updated | today | 2 days ago | today | today |
| Works on Android 16 / S26 Ultra | ❌ | ❌ | ⚠️ | ✅ |
| Fluxbox as fallback for broken DEs | ❌ | ❌ | ❌ | ✅ |
| Samsung Auto Blocker docs | ❌ | ❌ | ❌ | ✅ |
| Samsung battery whitelist docs | ❌ | ❌ | ❌ | ✅ |
| DNS fix inside chroot | ❌ | ❌ | ❌ | ✅ |
| postgresql-18 nuclear fix | ❌ | ❌ | ❌ | ✅ |
| glycin/bwrap explanation | ❌ | ❌ | ❌ | ✅ |
| Canonical startup file (fbpanel + tray + rofi) | ❌ | ❌ | ❌ | ✅ |
| scrcpy + adb control from Mac | ❌ | ❌ | ❌ | ✅ |

The 3 existing projects all assume XFCE/MATE/GNOME work. They don't on 2026 devices due to the bwrap/glycin issue. This project fills that gap.

---

## Files in this repo

```
samsung-kali-nethunter-rootless/
├── README.md                              # This file
├── LICENSE                                 # GPL-3.0
├── install.sh                              # The main installer (run in Termux + chroot)
├── control-from-mac.sh                     # scrcpy + adb companion script
├── fluxbox/
│   ├── startup                             # Canonical Fluxbox startup file
│   ├── keys                                # Keybindings (Ctrl+Alt+R for rofi)
│   └── rofi-config.rasi                    # rofi with icons
├── references/
│   ├── glycin-bwrap-analysis.md            # Why XFCE doesn't work in 2026
│   ├── samsung-notes.md                    # Samsung-specific caveats
│   └── proot-pr-359.md                     # The upstream proot fix
├── scripts/
│   ├── fix-postgresql.sh                   # Nuclear postgresql-18 fix
│   ├── fix-dns.sh                          # Write /etc/resolv.conf
│   ├── install-fluxbox.sh                  # Fluxbox + tools installer
│   ├── configure-vnc.sh                    # VNC xstartup + password
│   ├── install-tools.sh                    # Offensive security tools
│   └── start-kex.sh                        # VNC server starter
└── docs/
    ├── INSTALL.md                          # Detailed install walkthrough
    ├── TROUBLESHOOTING.md                  # Every error we hit
    └── SAMSUNG.md                          # Samsung-specific notes
```

---

## Verification

After the install, verify everything works:

```bash
# Drop into the chroot
nethunter -r

# Check the tools
which nmap msfconsole sqlmap burpsuite wireshark gobuster ffuf seclists
# All should return /usr/bin/<tool>

# Check the OS
cat /etc/os-release | grep PRETTY
# Should show: PRETTY_NAME="Kali GNU/Linux Rolling"

# Check the network (after running the DNS fix)
curl -sSLI http://http.kali.org 2>&1 | head -3
# Should show: HTTP/1.1 200 OK

# Check Metasploit
msfconsole -q -x 'db_status; exit'
# Should show: postgresql selected, no connection (proot can't run postgres daemon — OK)
```

---

## Daily use

```bash
# 1. Open Termux on the phone
# 2. Start VNC: nethunter kex &
# 3. Open NetHunter KeX app on the phone, enter password
# 4. Use the desktop
```

### Common commands

```bash
# Drop into the chroot
nh                  # user kali
nhr                 # user root
hack                # same as nhr

# Quick app launchers (from Termux)
kali-nmap IP        # run nmap as root in chroot
kali-msf            # start msfconsole
kali-burp           # start burpsuite GUI
kali-wire           # start wireshark GUI
kali-fire           # start firefox-esr GUI

# Check chroot status
nhstat
```

---

## Tested on

- ✅ **Samsung Galaxy S26 Ultra** (SM-S948B, Snapdragon 8 Elite Gen 5, Android 16, One UI 8)
- 🟡 Should work on any Android 13+ device with Termux (Samsung S24/S25, OnePlus 12/13, Pixel 8/9)

---

## References

- [Kali NetHunter Rootless docs (kali.org)](https://www.kali.org/docs/nethunter/nethunter-rootless/) — the official but stale guide
- [Termux-X11 on GitHub](https://github.com/termux/termux-x11) — alternative graphical layer
- [proot PR #359](https://github.com/termux/proot/pull/359) — the bwrap fix (merged 2026-06-01, not yet in Termux)
- [LinuxDroidMaster/Termux-Desktops#142](https://github.com/LinuxDroidMaster/Termux-Desktops/issues/142) — the original glycin/bwrap bug report
- [jorexdeveloper/termux-nethunter](https://github.com/jorexdeveloper/termux-nethunter) — most similar existing project

---

## License

GPL-3.0. See [LICENSE](LICENSE).

---

## Contributing

PRs welcome! Especially:
- Tests on other Samsung devices (S24, S25, etc.)
- Tests on non-Samsung devices (OnePlus, Pixel, etc.)
- termux-x11 path (alternative to KeX VNC)
- New tools or Fluxbox customizations
