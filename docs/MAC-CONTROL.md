# Controlling the Android Device from your Mac

This document covers all the ways to control your Samsung Galaxy phone (or any Android 13+ device) from your Mac. The full setup uses three tools working together:

- **adb** — Android Debug Bridge, for shell, file transfer, app installs
- **scrcpy** — Screen mirroring with keyboard/mouse control
- **NetHunter KeX** — VNC client for the Kali chroot desktop (only needed for the Kali setup)

For a quick interactive menu that wraps all of these, use the **`control-from-mac.sh`** script in the project root.

---

## Table of contents

- [Initial setup](#initial-setup)
- [Tool 1: adb (Android Debug Bridge)](#tool-1-adb-android-debug-bridge)
  - [Verify the connection](#verify-the-connection)
  - [Run shell commands on the phone](#run-shell-commands-on-the-phone)
  - [Install APKs](#install-apks)
  - [File transfer (push/pull)](#file-transfer-pushpull)
  - [Take screenshots](#take-screenshots)
  - [Send text to the focused app](#send-text-to-the-focused-app)
  - [Send key events (Home, Back, etc.)](#send-key-events-home-back-etc)
  - [Set up wireless ADB (unplug the USB cable)](#set-up-wireless-adb-unplug-the-usb-cable)
- [Tool 2: scrcpy (Screen Mirror)](#tool-2-scrcpy-screen-mirror)
  - [Basic usage](#basic-usage)
  - [Recording the screen](#recording-the-screen)
  - [Wireless scrcpy](#wireless-scrcpy)
  - [Keyboard shortcuts (when scrcpy window is focused)](#keyboard-shortcuts-when-scrcpy-window-is-focused)
  - [Drag & drop file transfer](#drag--drop-file-transfer)
- [Tool 3: NetHunter KeX (VNC for Kali)](#tool-3-nethunter-kex-vnc-for-kali)
- [Tool 4: ssh (terminal into the Kali chroot)](#tool-4-ssh-terminal-into-the-kali-chroot)
- [Tool 5: control-from-mac.sh (the all-in-one menu)](#tool-5-control-from-macsh-the-all-in-one-menu)
- [Troubleshooting](#troubleshooting)

---

## Initial setup

### Install adb + scrcpy on the Mac

```bash
brew install android-platform-tools scrcpy
```

Verify:

```bash
adb --version       # Android Debug Bridge version 1.0.41 or newer
scrcpy --version    # scrcpy 4.0 or newer
```

### Enable USB debugging on the phone

1. **Enable Developer Options:**
   `Settings → About Phone → Software Information → tap Build Number 7 times`
   (You'll see a toast: "You are now a developer!")

2. **Enable USB Debugging:**
   `Settings → Developer Options → USB Debugging: ON`

3. **Set USB Configuration:**
   `Settings → Developer Options → Default USB Configuration → File Transfer`
   (Default is "Charging only" which blocks adb.)

4. **(Samsung only) Turn off Auto Blocker:**
   `Settings → Device Care → Auto Blocker: OFF`
   (This is a software security feature, not a Knox trip. Warranty is unaffected.)

5. **(Samsung only) Whitelist Termux from battery optimization:**
   - `Settings → Device Care → Battery → Background Usage Limits → Never Sleeping Apps → Add Termux`
   - Long-press the Termux icon → **App Info** → **Battery** → select **Unrestricted**

### Connect the phone

1. Plug the phone into the Mac via USB-C
2. On the phone: pull down the notification shade → tap the "USB for file transfer" notification → ensure it says "File Transfer" mode
3. On the phone: accept the "Allow USB debugging?" popup → check **"Always allow from this computer"** → tap **Allow**

---

## Tool 1: adb (Android Debug Bridge)

`adb` is the swiss-army knife for talking to Android. It's part of the `android-platform-tools` package.

### Verify the connection

```bash
adb devices
```

Expected output:

```
List of devices attached
RFGL432J9EZ    device
```

If you see "unauthorized", re-do the USB debugging setup steps above.

If you see "offline" or no device, try:

```bash
adb kill-server
adb start-server
adb devices
```

### Run shell commands on the phone

```bash
# Open a shell into the phone's Android filesystem
adb -d shell

# Run a single command
adb -d shell getprop ro.build.fingerprint
# Output: samsung/m3qxxx/m3q:16/BP4A.251205.006/S948BXXS3AZF1_OXM3AZF1:user/release-keys

# Check device info
adb -d shell getprop ro.product.model       # e.g. SM-S948B
adb -d shell getprop ro.build.version.release  # e.g. 16
adb -d shell getprop ro.build.version.security_patch  # e.g. 2026-06-05
adb -d shell getprop ro.boot.warranty_bit   # should be 0x0000 (Samsung Knox)
```

### Install APKs

```bash
# Install an APK from the Mac
adb -d install ~/Downloads/termux.apk

# Install and replace existing
adb -d install -r ~/Downloads/termux.apk

# Install multiple APKs at once (for split APKs)
adb -d install-multiple app-part1.apk app-part2.apk

# Uninstall an app
adb -d uninstall com.termux

# List installed apps
adb -d shell pm list packages | grep -i termux
```

### File transfer (push/pull)

```bash
# Copy a file from the Mac to the phone
adb -d push ~/Desktop/photo.jpg /sdcard/Pictures/

# Copy a file from the phone to the Mac
adb -d pull /sdcard/Pictures/photo.jpg ~/Desktop/

# Copy an entire directory
adb -d push ~/myapp/ /sdcard/myapp/

# Use the phone's internal storage path
# On modern Android, /sdcard is the "shared" storage; /storage/emulated/0 is the user's home
```

### Take screenshots

```bash
# Take a screenshot
adb -d shell screencap -p /sdcard/screenshot.png

# Pull it to the Mac
adb -d pull /sdcard/screenshot.png ~/Desktop/screenshot-$(date +%Y%m%d-%H%M%S).png

# One-liner with timestamp
adb -d exec-out screencap -p > ~/Desktop/screen-$(date +%Y%m%d-%H%M%S).png
```

### Send text to the focused app

This is great for typing on the phone from your Mac keyboard when the Hacker's Keyboard is up.

```bash
# Type a string into whatever app is focused on the phone
adb -d shell input text "hello world"

# Note: spaces must be escaped as %s in the string
adb -d shell input text "hello%sworld"
```

Limitations: adb input text doesn't handle special shell characters well (`>`, `&`, `|`, `;`, `*`, `?`, `'`, `"`). For complex commands, use the VNC xfce4-terminal on the phone.

### Send key events (Home, Back, etc.)

```bash
# Go home
adb -d shell input keyevent KEYCODE_HOME

# Go back
adb -d shell input keyevent KEYCODE_BACK

# Open recent apps
adb -d shell input keyevent KEYCODE_APP_SWITCH

# Wake/unlock the screen
adb -d shell input keyevent KEYCODE_WAKEUP
adb -d shell input keyevent KEYCODE_MENU

# Open notifications
adb -d shell input keyevent KEYCODE_NOTIFICATION

# Power button (long press = power menu)
adb -d shell input keyevent KEYCODE_POWER
```

For the full list of keycodes, see: `adb -d shell input keyevent --longpress KEYCODE_POWER` or check [Android's KeyEvent documentation](https://developer.android.com/reference/android/view/KeyEvent).

### Set up wireless ADB (unplug the USB cable)

Once you've done the USB setup once, you can switch to wireless:

```bash
# On the phone, get its Wi-Fi IP (in Termux):
ip -4 addr show wlan0 | grep inet

# On the Mac:
adb -d tcpip 5555                    # enable ADB over TCP/IP on the phone
adb connect <phone-ip>:5555          # connect wirelessly

# Output: connected to 192.168.1.42:5555

# Unplug the USB cable. You can now use the phone wirelessly:
adb -s 192.168.1.42:5555 shell

# Or set the wireless address as the default:
adb -s 192.168.1.42:5555 install myapp.apk
```

The wireless connection stays alive until the phone reboots. To re-enable after a reboot, plug in via USB and re-run the `tcpip 5555` and `connect` commands.

---

## Tool 2: scrcpy (Screen Mirror)

`scrcpy` mirrors the entire phone screen to a window on your Mac, with full keyboard and mouse control. It's much better than VNC for general phone interaction because it captures the actual Android screen (not just a chroot running inside an app).

### Basic usage

```bash
# Just mirror the phone (USB)
scrcpy

# Specify a device (if you have multiple)
scrcpy -s <serial>

# Wireless ADB
scrcpy --tcpip=<phone-ip>:5555
```

A window will pop up on your Mac showing the phone screen. Click on it to interact, type on your Mac keyboard to send keys, and scroll/click with the trackpad.

### Recording the screen

```bash
# Record to MP4
scrcpy --record ~/Desktop/recording.mp4

# Record without showing the window
scrcpy --no-display --record ~/Desktop/recording.mp4
```

### Wireless scrcpy

After setting up wireless ADB (see above), you can do scrcpy over Wi-Fi:

```bash
scrcpy --tcpip=192.168.1.42:5555
```

Latency is higher than USB (~30-100ms vs <30ms), but it's fine for most uses.

### Keyboard shortcuts (when scrcpy window is focused)

| Shortcut | Action |
|---|---|
| `Cmd+S` | Toggle fullscreen |
| `Cmd+H` | Toggle hide mouse cursor |
| `Cmd+P` | Toggle power button (lock/unlock phone) |
| `Cmd+B` | Toggle back button |
| `Cmd+M` | Toggle menu button |
| `Cmd+O` | Turn phone screen off (saves battery) |
| `Cmd+Shift+O` | Turn phone screen back on |
| `Cmd+Shift+S` | Take screenshot, save to Mac |
| `Cmd+R` | Rotate screen |
| `Cmd+N` | Expand notification panel |
| `Cmd+Shift+N` | Collapse notification panel |
| `Cmd+W` | Close scrcpy window |
| `Right-click` | Android back button |
| `Middle-click` | Android home button |
| `2x click and hold` | Android recent apps |
| Drag & drop | Copy files from Mac to phone |

### Drag & drop file transfer

Drag any file from Finder into the scrcpy window. It'll be copied to the phone's `Download/` folder (or to `/sdcard/`).

```bash
# Configure a different default drop location
scrcpy --push-target=/sdcard/Pictures/
```

---

## Tool 3: NetHunter KeX (VNC for Kali)

NetHunter KeX is the VNC client for the Kali chroot's graphical desktop. It's **only needed for the Kali NetHunter setup** — not for general phone control.

```bash
# On the phone (in Termux):
nethunter kex &amp;       # start VNC server

# Open NetHunter KeX app on the phone, enter password, connect
# The Fluxbox desktop appears
```

You can also combine KeX with scrcpy: mirror the phone, see the VNC desktop in the scrcpy window, and interact with it using your Mac keyboard/mouse.

---

## Tool 4: ssh (terminal into the Kali chroot)

If you have sshd running in the Kali chroot, you can connect from the Mac:

```bash
# On the phone (in the chroot, one-time setup):
apt install -y openssh-server
ssh-keygen                      # generate a key
service ssh start                # start sshd

# On the Mac:
ssh -p 8022 kali@<phone-ip>      # default sshd port in NetHunter is 8022
```

To use the Mac's ssh key in the chroot:

```bash
# On the Mac, copy your public key:
cat ~/.ssh/id_rsa.pub

# On the phone, in the chroot:
mkdir -p ~/.ssh
echo "<paste-the-key-here>" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

Now you can ssh in without a password:

```bash
ssh -p 8022 kali@192.168.1.42
```

---

## Tool 5: control-from-mac.sh (the all-in-one menu)

The project ships with a 9-option menu script that wraps all of the above:

```bash
cd ~/samsung-kali-nethunter-rootless
./control-from-mac.sh
```

This gives you:

```
What do you want to do?

  1. Launch scrcpy (mirror phone screen to Mac)
  2. Open adb shell (terminal access to phone)
  3. Send a text string to the focused app
  4. Set up wireless (TCP) ADB — disconnect USB after
  5. Show device info again
  6. Take a screenshot of the phone
  7. Install APKs from this Mac to the phone
  8. Pull a file from the phone to this Mac
  9. Push a file from this Mac to the phone
  0. Quit
```

The script handles all the boilerplate (installing adb + scrcpy, verifying the device is connected, prompting for IP addresses, etc.).

---

## Troubleshooting

### `adb devices` shows "unauthorized"

The phone is connected but you haven't accepted the RSA prompt.

**Fix:** On the phone, pull down the notification shade. Look for a popup that says "Allow USB debugging?". Tap **Allow** and check "Always allow from this computer".

### `adb devices` shows "no permissions" (Linux only)

Linux requires udev rules for adb. macOS does not have this issue.

### scrcpy crashes with "Could not find any video device"

The phone's screen is locked or the USB connection is broken.

**Fix:** Wake the phone screen with the power button, unlock it, then re-run scrcpy.

### scrcpy window is black

The phone is in deep sleep. Press the power button to wake it.

### `adb -d install termux.apk` fails with "INSTALL_FAILED_USER_RESTRICTED"

Either Auto Blocker is on (Samsung) or "Install unknown apps" is disabled for adb.

**Fix:**
- **Samsung:** turn off Auto Blocker (Settings → Device Care → Auto Blocker → OFF)
- **Other:** Settings → Apps → Special access → Install unknown apps → adb → Allow

### `adb -d shell` says "permission denied"

You're trying to access Termux's private storage from adb, which is blocked by Android's app sandbox. Use `nethunter -r` to access the chroot's filesystem instead.

### `adb input text` typing is mangled

URL-encoded shell-special characters (`%26%26` for `&&`, `%7C` for `|`, `%3E` for `>`, `%3C` for `<`, `%22` for `"`) get typed as literal characters, not decoded. Only `%s` (space) is decoded by adb input.

**Fix:** For complex shell commands, type them directly in the VNC xfce4-terminal on the phone, or use the chroot's own bash.

### Wireless ADB keeps disconnecting

The phone's IP may have changed (DHCP lease renewed). Re-run:

```bash
# Find the new IP
adb -d shell "ip -4 addr show wlan0 | grep inet"

# Reconnect
adb connect <new-ip>:5555
```

### Phone Wi-Fi keeps disconnecting

Samsung's battery optimization is aggressive. Settings → Device Care → Battery → Background Usage Limits → Never Sleeping Apps → add **Wireless ADB** (or whatever the process is called).

---

## Reference: useful one-liners

```bash
# Watch the phone's log in real-time (for debugging)
adb -d logcat | grep -i "yourapp"

# Dump the phone's full info as JSON
adb -d shell "ip -json addr" | python3 -m json.tool

# Take 5 screenshots in a row
for i in 1 2 3 4 5; do
  adb -d exec-out screencap -p > ~/Desktop/shot-$i.png
  sleep 1
done

# Install all APKs from a directory
for apk in ~/Downloads/*.apk; do
  adb -d install "$apk"
done

# Find which app owns a port
adb -d shell "netstat -tulnp 2>/dev/null | grep 5901"

# Get the phone's battery level
adb -d shell dumpsys battery | grep level

# Toggle the phone's Wi-Fi
adb -d shell svc wifi enable
adb -d shell svc wifi disable

# Reboot the phone
adb -d reboot

# Boot into recovery (CAREFUL — this is dangerous)
adb -d reboot recovery

# Boot into bootloader (CAREFUL — this is also dangerous)
adb -d reboot bootloader
```

---

For general troubleshooting of the Kali chroot itself (not the Mac control), see [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
