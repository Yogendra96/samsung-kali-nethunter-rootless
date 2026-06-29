# Why XFCE/MATE/GNOME Don't Work in proot on 2026+ Android

> **TL;DR:** The crash is `xfwm4: Unsupported GL renderer (llvmpipe)` followed by `bwrap` failing in glycin-loaders. The fix is upstream in proot master but not yet in Termux. **Use Fluxbox in the meantime.**

## The crash chain

When you try to start XFCE inside a proot chroot on a 2026+ Android device, you get:

```
xfwm4-WARNING: Unsupported GL renderer (llvmpipe (LLVM 15.0.7, 128 bits))
libclock-Message: could not get proxy for org.freedesktop.login1
(xfce4-panel): libclock-WARNING: could not instantiate a sleep monitor
** WARNING **: Failed to get system bus: Could not connect
(xfce4-session): failed to run script: /usr/bin/pm-is-supported (No such file or directory)
…
(xfce4-session): … ComparingUpdateTracker: 0 pixels in / 0 pixels out, (1:nan ratio)
** ERROR **: Bail out! Wnck:ERROR:default_icon_at_size: assertion failed
xfsettingsd: libxfce4ui-WARNING: ICE I/O Error
** ERROR **: Disconnected from session manager.
Aborted
```

The visible symptom is that the session starts for 1-3 seconds and then dies with `Aborted`.

## Root cause

XFCE 4.20+ uses gdk-pixbuf for icon loading. Modern gdk-pixbuf delegates SVG loading to a separate process called `glycin-loaders` (from the GNOME `glycin` project). `glycin-loaders` sandboxes itself with `bwrap` (bubblewrap) using `--unshare-all`:

```bash
# Run by gtk to load an SVG icon
bwrap --unshare-all --bind /usr/lib /usr/lib --bind ... /usr/libexec/glycin-svg ...
```

`bwrap --unshare-all` requires **Linux user namespaces** which **proot cannot fake**. proot intercepts syscalls and translates paths, but it doesn't create real user namespaces. So `bwrap` exits with an error like:

```
bwrap: setting up uid map: Permission denied
```

When bwrap fails, gdk-pixbuf can't load the icon. GTK apps then can't initialize, the XFCE session manager (`xfce4-session`) sees its components dying, and it aborts with the `ComparingUpdateTracker` error (which is a side effect of the compositor and panel having a half-baked state when the session manager dies).

## Same root cause for MATE and GNOME

- **MATE:** `GLib-GIO-ERROR: Settings schema 'org.mate.session' is not installed` — the GSettings schemas can't be found because proot doesn't translate the paths correctly
- **GNOME:** needs systemd + logind, which proot can't fake
- **LXDE/LXQt:** similar GSettings issues

## Why Fluxbox works

Fluxbox is a tiny (~50 KB) standalone window manager that:
- Doesn't use gdk-pixbuf
- Doesn't use bwrap
- Doesn't use dbus session bus
- Doesn't use systemd
- Has its own freedesktop.org menu (hard-coded, not dynamically discovered)

It has a `~/.fluxbox/startup` file that lets you manually launch whatever you want (panel, tray, wallpaper, etc.), none of which depend on the broken bwrap/GLib stack.

## The upstream fix (not yet in Termux)

The proot project has a fix in master:

- **PR:** [termux/proot#359 — Hijack namespace requests + other fixes to make bwrap working](https://github.com/termux/proot/pull/359)
- **Merged:** 2026-06-01
- **Author:** Termux contributors
- **Status:** in master, NOT yet in a Termux release

When `pkg update && pkg upgrade proot` ships a version with this fix, XFCE/MATE/GNOME may start working again in proot. Until then, Fluxbox is the only option.

## Workaround: monitor for the fix

```bash
# In Termux, periodically check for a new proot version
pkg update &amp;&amp; pkg upgrade proot

# Check current proot version
proot --version
# Current Termux version: v5.1.107.81 (as of 2026-06-29)
# When the version bumps, check if it includes PR #359
```

When XFCE starts working again, the existing scripts can be updated to use `xfce4-session` instead of Fluxbox. The Fluxbox-based setup will still work; you'll just have a choice.

## References

- [termux/proot#359](https://github.com/termux/proot/pull/359) — the upstream fix
- [LinuxDroidMaster/Termux-Desktops#142](https://github.com/LinuxDroidMaster/Termux-Desktops/issues/142) — the original report (Arch Linux + XFCE)
- [termux/proot-distro#644](https://github.com/termux/proot-distro/issues/644) — bwrap incompatibility in proot (closed 2026-06-20 with the fix)
- [termux/termux-x11#749](https://github.com/termux/termux-x11/issues/749) — same issue, termux-x11 side
