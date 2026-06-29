#!/usr/bin/env bash
# install-fluxbox.sh — install Fluxbox and the desktop tools
# Run inside the chroot as root.
#
# Why Fluxbox: it's the only desktop environment that works in proot
# on 2026+ Android devices. XFCE/MATE/GNOME all crash because of a
# glycin/bwrap incompatibility. See references/glycin-bwrap-analysis.md
# for the full story.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }

log "Installing Fluxbox + xfce4-terminal + rofi + fbpanel + stalonetray + conky..."

apt install -y \
    fluxbox \
    xfce4-terminal \
    dbus-x11 \
    menu \
    pcmanfm \
    rofi \
    dmenu \
    feh \
    conky \
    stalonetray \
    fbpanel \
    htop \
    adwaita-icon-theme \
    notification-daemon

log "Done. The Fluxbox xstartup is configured by the main install.sh."
log "After install: nethunter kex &amp; (from Termux), then open NetHunter KeX app."
