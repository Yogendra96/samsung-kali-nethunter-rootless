# proot PR #359 — when XFCE might work again

The proot project has the upstream fix for the bwrap/namespace issue. Once it ships to Termux, XFCE/MATE/GNOME will work inside the chroot and this project can be simplified.

## Status

- **PR:** [termux/proot#359](https://github.com/termux/proot/pull/359)
- **Title:** "Hijack namespace requests + other fixes to make bwrap working"
- **Merged:** 2026-06-01
- **Status:** in master, **NOT yet in a Termux release**
- **Proot in Termux:** v5.1.107.81 (as of 2026-06-29)

## What the fix does

1. Simulates the netlink replies that `bwrap --unshare-all` needs to succeed
2. Hijacks certain proot syscalls so bwrap thinks it's in a real user namespace
3. As a bonus, this also fixes `ip addr show` and Node.js `os.networkInterfaces()` inside proot

## How to check if the fix is in your Termux

```bash
# In Termux (not the chroot):
proot --version
```

- If version >= 5.2.x with the namespace fix: XFCE should work
- If version is still 5.1.107.x: use Fluxbox

To update:
```bash
pkg update &amp;&amp; pkg upgrade proot
```

## When XFCE works again

Replace the Fluxbox xstartup with XFCE:

```bash
# In the chroot as root:
apt install -y xfce4-session xfwm4 xfce4-panel xfce4-terminal dbus-x11

cat > /etc/X11/Xtigervnc-session <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session xfce4-session
EOF
chmod +x /etc/X11/Xtigervnc-session

nethunter kex kill
nethunter kex &
```

The Fluxbox-based setup will still work; you just have a choice. We'll update this project to recommend XFCE once the fix ships.

## Tracking the issue

- Watch [termux/proot releases](https://github.com/termux/proot/releases) for new versions
- Search for "namespace" in release notes
- The commit hash for the fix is in PR #359 — grep for it in proot's CHANGELOG
