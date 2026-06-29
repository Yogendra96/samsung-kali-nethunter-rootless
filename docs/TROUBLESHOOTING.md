# Troubleshooting

Every error we hit during the original setup, and how to fix it.

## Phone-side errors

### `adb devices` shows "unauthorized"

The phone is connected but you haven't accepted the RSA prompt.

**Fix:** On the phone, pull down the notification shade. Look for a popup that says "Allow USB debugging?". Tap **Allow** and check "Always allow from this computer".

If no popup appears, try:
1. Unplug the USB cable
2. `adb kill-server`
3. Replug
4. Look for the popup again

### `adb devices` shows "no permissions" (Linux only)

Linux requires udev rules for adb. macOS does not have this issue.

### `apt update` fails with "Temporary failure resolving 'http.kali.org'"

The chroot's DNS isn't configured. proot doesn't reliably inherit Android's DNS resolver.

**Fix:** In the chroot as root:

```bash
cat > /etc/resolv.conf <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
```

Then test:
```bash
ping -c 1 -W 2 http.kali.org
```

### Wi-Fi has disconnected and `apt update` fails

The phone's Wi-Fi has dropped. The chroot's network is broken too because proot inherits the host network.

**Fix:**
1. On the phone, pull down the notification shade
2. Tap the Wi-Fi tile to disable, then enable
3. Or: `Settings → Connections → Wi-Fi → [your network]`

After reconnect, re-run `apt update`.

### Termux was killed in the background

Samsung's battery optimization killed Termux (and with it, the chroot).

**Fix:** Re-whitelist Termux:
1. `Settings → Device Care → Battery → Background Usage Limits → Never Sleeping Apps → Add Termux`
2. Long-press Termux icon → App Info → Battery → **Unrestricted**

If the chroot was running, restart it with:
```bash
nethunter kex &amp;
```

### The phone shows "USB debugging blocked by Auto Blocker"

Samsung Auto Blocker is enabled.

**Fix:** `Settings → Device Care → Auto Blocker → OFF`. This is a software toggle, doesn't affect warranty or Knox.

## Chroot-side errors

### `apt install` fails with "Sub-process /usr/bin/dpkg returned an error code (1)" — postgresql-18

The postgresql-18 package's prerm script tries to start the postgres daemon, which can't run in proot.

**Fix (nuclear):** In the chroot as root:

```bash
rm -rf /var/lib/dpkg/info/postgresql* \
       /var/lib/dpkg/info/*postgresql* \
       /usr/lib/postgresql \
       /var/lib/postgresql \
       /var/log/postgresql \
       /var/cache/apt/archives/postgresql*.deb
rm -f /var/lib/dpkg/triggers/File /var/lib/dpkg/triggers/Lock
dpkg --configure -a
apt --fix-broken install -y
```

**Fix (less nuclear):** Mark postgresql as held so it never updates:
```bash
apt-mark hold postgresql-18 postgresql-18-jit
```

### VNC server starts but XFCE/MATE/GNOME crashes with "Aborted" or "ICE I/O Error"

This is the **glycin/bwrap incompatibility**. XFCE/MATE/GNOME all fail in proot on 2026 Android devices because they depend on gdk-pixbuf and bubblewrap, neither of which work in proot.

**Fix:** Don't use XFCE/MATE/GNOME. Use **Fluxbox** instead.

```bash
apt install -y fluxbox xfce4-terminal dbus-x11 rofi fbpanel stalonetray conky adwaita-icon-theme
```

See [references/glycin-bwrap-analysis.md](references/glycin-bwrap-analysis.md) for the full root cause analysis.

### VNC server is running but `NetHunter KeX` says "Connection refused"

The VNC server didn't actually start. The Fluxbox session crashed before it could bind to port 5901.

**Fix:** In the chroot:

```bash
# Make sure your xstartup is correct
cat /etc/X11/Xtigervnc-session
# Should show:
# #!/bin/sh
# unset SESSION_MANAGER
# unset DBUS_SESSION_BUS_ADDRESS
# exec dbus-launch --exit-with-session /home/kali/.fluxbox/startup

# Then start fresh
nethunter kex kill
nethunter kex &
```

### `which burpsuite` returns "command not found"

burpsuite may not be installed. Install it:

```bash
apt install -y burpsuite seclists java-wrappers
```

This was the case in the original setup because the `apt install -y <many packages>` command got mangled by `adb input text` URL encoding. The installer in this project installs them explicitly.

### `rofi` says "No valid backend was found. Make sure to launch rofi from a valid X11 or Wayland session."

This happens when rofi is run from a shell that doesn't have the right `DISPLAY` and `XAUTHORITY` env vars set (e.g., a shell that started before VNC came up, or one that was started with a different proot command).

**Fix:** Set the env vars explicitly:

```bash
DISPLAY=:1 XAUTHORITY=/home/kali/.Xauthority rofi -show drun
```

If you want this in the Fluxbox keys file:

```bash
cat > /home/kali/.fluxbox/keys <<'EOF'
Control Mod1 r :ExecCommand DISPLAY=:1 XAUTHORITY=/home/kali/.Xauthority rofi -show drun
EOF
```

### Fluxbox taskbar (fbpanel) doesn't show

Common causes:

1. **fbpanel crashed** — check by running it manually:
   ```bash
   fbpanel 2>&1 | head -20
   ```
   If it complains about missing icon theme, install it:
   ```bash
   apt install -y adwaita-icon-theme
   ```

2. **fbpanel started before X was ready** — make sure your `~/.fluxbox/startup` has `sleep 1` at the top.

3. **fbpanel is on the wrong display** — verify the Fluxbox startup uses the same DISPLAY:
   ```bash
   cat /home/kali/.fluxbox/startup
   ```
   Should not need to set DISPLAY if the chroot is the right one (kex uses `-w /home/kali`).

### NetHunter KeX shows a black screen

The VNC server is up but the desktop session crashed (e.g., XFCE crashed). Use the canonical Fluxbox startup to avoid this.

### Kex says "Unable to connect to VNC server"

Either the VNC server is dead or the phone's IP/network has issues. From Termux on the phone:

```bash
# Check if VNC is running
ps -ef | grep Xtigervnc

# Check the VNC password file
ls -la /home/kali/.config/tigervnc/passwd

# Restart VNC
nethunter kex stop
nethunter kex &
```

## Mac-side errors

### scrcpy crashes with "ERROR: Could not find any video device"

The phone's screen is locked or the USB connection is broken.

**Fix:** Wake the phone screen with the power button, unlock it, then re-run scrcpy.

### scrcpy window is black

The phone is in deep sleep. Press the power button to wake it.

### `adb -d install termux.apk` fails with "INSTALL_FAILED_USER_RESTRICTED"

Either Auto Blocker is on (Samsung) or "Install unknown apps" is disabled for adb.

**Fix:**
- Samsung: turn off Auto Blocker
- Other: `Settings → Apps → Special access → Install unknown apps → adb → Allow`

### adb sees the phone but `adb -d shell` says "permission denied"

You're trying to access Termux's private storage from adb, which is blocked by Android's app sandbox. Use `nethunter -r` to access the chroot's filesystem instead.

## Everything else

### `top` doesn't work

Proot limitation — proot can't fake the `/proc` filesystem well enough for `top` to work. Use `ps -ef` instead.

### `airmon-ng start wlan0` runs but doesn't put the Wi-Fi chip in monitor mode

Proot limitation — proot can't directly control the Wi-Fi hardware. For real Wi-Fi pentesting, you need a rooted phone with a NetHunter kernel image (no such image exists for beryllium/S26 Ultra in 2026).

### `metasploit` `db_status` returns "no connection"

Postgresql can't run inside proot. Metasploit still works for everything except database-backed features. Use `msfconsole` directly.

### Phone gets hot during long scans

The Snapdragon 8 Elite Gen 5 thermal throttles under sustained load. Use `nice` to de-prioritize:
```bash
nice -n 19 nmap -sV 192.168.1.0/24
```

### I want to add my own custom tools to the chroot

`adb -d push ./mytool /data/data/com.termux/files/home/`
`nethunter -r "cp /home/kali/mytool /usr/bin/ &amp;&amp; chmod +x /usr/bin/mytool"`
