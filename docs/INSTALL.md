# Install Guide — samsung-kali-nethunter-rootless

This is a detailed step-by-step walkthrough. If you just want the quick version, see [README.md](README.md).

## What you'll need

- **Phone:** Samsung Galaxy S24 / S25 / S26 / A series, or any Android 13+ device with Termux
- **Mac:** running macOS 12+ (Intel or Apple Silicon)
- **USB-C cable** (the one that came with the phone works)
- **Storage:** ~8 GB free on the phone for the chroot
- **Time:** ~30 minutes (15 min for download, 15 min for setup)
- **Network:** Wi-Fi on the phone (or use phone's data)

## Step 0: Install tools on the Mac

```bash
brew install android-platform-tools scrcpy
```

- `android-platform-tools` provides `adb` and `fastboot`
- `scrcpy` lets you mirror the phone screen on your Mac

Verify:
```bash
adb --version       # should print version 1.0.41 or newer
scrcpy --version    # should print scrcpy 4.0 or newer
```

## Step 1: Set up the phone for USB debugging

### 1a. Enable Developer Options

`Settings → About Phone → Software Information → tap Build Number 7 times`

You should see a toast message: "You are now a developer!"

### 1b. Enable USB Debugging

`Settings → Developer Options → USB Debugging: ON`

### 1c. Set USB Configuration

`Settings → Developer Options → Default USB Configuration → File Transfer`

(Default is "Charging only" which blocks ADB.)

### 1d. Disable Samsung Auto Blocker (Samsung only)

`Settings → Device Care → Auto Blocker → OFF`

This is a software toggle, not a Knox trip. Warranty is unaffected.

### 1e. Whitelist Termux from battery optimization (Samsung only)

1. `Settings → Device Care → Battery → Background Usage Limits → Never Sleeping Apps → Add Termux`
2. Long-press the **Termux** app icon → **App Info** → **Battery** → select **Unrestricted**

Without this, Samsung kills Termux in the background after ~10 minutes.

## Step 2: Connect the phone to the Mac

1. Plug the phone into the Mac via USB-C
2. On the phone: pull down the notification shade → tap the "USB for file transfer" notification → ensure it says "File Transfer" mode
3. On the phone: accept the "Allow USB debugging?" popup → check "Always allow from this computer" → tap **Allow**

## Step 3: Verify the connection

On the Mac, in Terminal:

```bash
adb devices
```

Expected output:
```
List of devices attached
RFGL432J9EZ    device
```

If you see "unauthorized", re-do step 2 (the RSA prompt).

## Step 4: Download the APKs to the Mac

You need two APKs:

### Termux

Download from **F-Droid** (the trusted open-source Android store): https://f-droid.org/en/packages/com.termux/

Verify the SHA256:
```bash
shasum -a 256 termux.apk
# Should match: fdd476982cd74f2f00aac12d3683b1fa260a0b2d146411b94e09d773be3a7b56
```

### NetHunter Store

Download from the official Kali site: https://store.nethunter.com/NetHunterStore.apk

Verify the SHA256:
```bash
shasum -a 256 NetHunterStore.apk
# Should match: 54661b4f326c65cd6037186dc7a503b2473a3b011ca0913244b13b056ac0c06e
```

## Step 5: Install the APKs

```bash
adb -d install termux.apk
adb -d install NetHunterStore.apk
```

Expected output for each:
```
Performing Streamed Install
Success
```

## Step 6: Install NetHunter-KeX from the Store

1. On the phone, open **NetHunter Store** (it has the Kali dragon icon)
2. Tap **Install** on:
   - **Termux** (probably already installed — skip if so)
   - **NetHunter-KeX** (the VNC client app)
   - **Hacker's Keyboard** (a full Linux-style keyboard)

> **Note:** the "Install" button may not visually change to "Installed" — this is a known Store bug. Check the phone's app drawer to confirm the apps are there.

## Step 7: Open Termux on the phone

1. Open **Termux** from the app drawer
2. If a "Termux setup" prompt appears, tap **OK** to grant storage permission

## Step 8: Update Termux

In Termux:

```bash
pkg update -y
pkg upgrade -y
pkg install -y wget ca-certificates
termux-setup-storage
```

The `termux-setup-storage` command will pop up a permission dialog on the phone — tap **Allow**.

## Step 9: Bootstrap the Kali chroot

In Termux:

```bash
wget -O install-nethunter-termux https://offs.ec/2MceZWr
chmod +x install-nethunter-termux
./install-nethunter-termux
```

The installer will ask which rootfs variant you want:
- **`full`** (recommended) — ~800 MB download, ~2.5 GB installed, all Kali tools
- **`nano`** — ~200 MB, minimal tools
- **`minimal`** — ~400 MB, middle ground

Choose **`full`** by typing `1` or just hitting Enter (full is default).

Wait for it to download and extract (~15 minutes).

## Step 10: Drop into the chroot and run the chroot-side installer

In Termux:

```bash
nethunter -r
```

You're now in the chroot as root. The prompt should change to `(root㉿localhost)-[~]#`.

Now run the main installer (or paste the full script from `install.sh`):

```bash
# If you have internet in the chroot (likely, since proot inherits the network):
curl -sSL https://raw.githubusercontent.com/YOUR-USERNAME/samsung-kali-nethunter-rootless/main/install.sh | bash

# Or, if you copied install.sh to the chroot via Termux:
bash /path/to/install.sh
```

The installer will:
1. Fix the wedged postgresql-18 (if present)
2. Fix the chroot's DNS
3. Update the chroot (`apt update` + `full-upgrade`)
4. Install offensive security tools (~1.5 GB download)
5. Install Fluxbox + desktop tools
6. Write the canonical Fluxbox startup file (with fbpanel, stalonetray, conky, rofi)
7. Configure the VNC server (tigervnc) with a random password
8. Add useful shell aliases to Termux

Total time: ~10-15 minutes depending on your internet.

## Step 11: Start the VNC desktop

In Termux (NOT the chroot):

```bash
nethunter kex &amp;
```

This starts the tigervnc server on port 5901. The output should look like:

```
New Xtigervnc server 'localhost:1 (kali)' on port 5901 for display :1.
```

**Write down the VNC password** that was generated (it was printed during the install).

## Step 12: Open NetHunter-KeX

1. On the phone, open **NetHunter KeX** (the VNC client app)
2. Enter the VNC password from step 11
3. Tap **Connect**

You should see the **Fluxbox desktop** with the **Kali dragon wallpaper** and the **xfce4-terminal maximized** with a `(kali㉿localhost)-[~]$` prompt.

Press **Ctrl+Alt+R** in the desktop to open **rofi** (app launcher).

## Step 13: Verify everything works

In the VNC xfce4-terminal:

```bash
# Should all return /usr/bin/<tool>
which nmap msfconsole sqlmap burpsuite wireshark gobuster ffuf seclists

# Should print "Kali GNU/Linux Rolling"
cat /etc/os-release | grep PRETTY

# Should show 1,800+ packages
ls /var/lib/dpkg/info/ | grep -c .
```

## Step 14: (Optional) Control the phone from your Mac

Now that the install is done, use the `control-from-mac.sh` script on the Mac to mirror the phone screen, send text, take screenshots, etc.

```bash
# On the Mac:
cd ~/path/to/samsung-kali-nethunter-rootless
./control-from-mac.sh
```

This gives you a menu of remote-control options.

## You're done! 🎉

You now have a full Kali Linux installation on your Samsung phone with:
- 1,800+ packages
- nmap, msfconsole, sqlmap, burpsuite, aircrack-ng, wireshark, gobuster, ffuf, seclists
- A graphical Fluxbox desktop with taskbar, system tray, wallpaper, app launcher
- No root, no Knox trip, no warranty void
- Persists across reboots

## Daily use

```bash
# 1. Open Termux on the phone
# 2. Start VNC: nethunter kex &amp;
# 3. Open NetHunter KeX app → connect
# 4. Use the desktop

# Quick app launchers (from Termux):
kali-nmap 192.168.1.1    # nmap as root
kali-msf                # msfconsole
kali-burp               # burpsuite GUI
kali-wire               # wireshark GUI
```

## Troubleshooting

If anything goes wrong, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
