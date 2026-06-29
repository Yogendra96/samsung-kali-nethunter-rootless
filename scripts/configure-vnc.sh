#!/usr/bin/env bash
# configure-vnc.sh — set up the VNC server (tigervnc) for the KeX client
# Run inside the chroot as root.
#
# The NetHunter KeX app on the phone connects to tigervnc on port 5901.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }

log "Writing the VNC xstartup to use Fluxbox..."

mkdir -p /etc/X11

cat > /etc/X11/Xtigervnc-session <<'VNCXEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session /home/kali/.fluxbox/startup
VNCXEOF
chmod +x /etc/X11/Xtigervnc-session

log "Setting the KeX VNC password (you'll need this in the NetHunter KeX app)..."

mkdir -p /home/kali/.config/tigervnc
if [ ! -f /home/kali/.config/tigervnc/passwd ]; then
    # Generate a random 12-character password
    RANDOM_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
    echo "$RANDOM_PASS" | vncpasswd -f > /home/kali/.config/tigervnc/passwd
    chmod 600 /home/kali/.config/tigervnc/passwd
    echo "[i] Generated random VNC password: $RANDOM_PASS"
    echo "[i] Write this down. Change later with: nethunter kex passwd"
fi

# Fix ownership
chown -R kali:kali /home/kali/.config 2>/dev/null || true

log "Done. Start the VNC server from Termux with: nethunter kex &amp;"
