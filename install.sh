#!/usr/bin/env bash
#
# samsung-kali-nethunter-rootless — one-liner installer
# Tested on: Samsung Galaxy S26 Ultra (SM-S948B, Snapdragon 8 Elite Gen 5, Android 16)
# Also works on: any Android 13+ device with Termux (Samsung, OnePlus, Pixel, etc.)
#
# What this does:
#   1. Installs Termux + NetHunter Store + NetHunter KeX via adb
#   2. Bootstraps the Kali chroot in Termux via the official install script
#   3. Fixes the known issues that block fresh chroots:
#       - DNS inside the chroot (write nameserver 8.8.8.8 to /etc/resolv.conf)
#       - postgresql-18 prerm script (atomic re-install via dpkg --configure -a)
#   4. Updates the chroot (apt update + full-upgrade)
#   5. Installs the offensive security tools
#   6. Installs the Fluxbox desktop (the only working DE in proot on 2026 devices)
#   7. Sets up the canonical Fluxbox startup with fbpanel + stalonetray + conky + rofi
#   8. Configures VNC (tigervnc) on port 5901
#   9. Starts the KeX VNC server
#
# No root. No bootloader unlock. No Knox trip. No warranty void.
#
# Usage (on the Mac, with the phone connected via USB):
#   adb -d install termux.apk && adb -d install NetHunterStore.apk
#   # then on the phone, in Termux:
#   curl -sSL https://raw.githubusercontent.com/.../install.sh | bash

set -euo pipefail

# ============================================================
# Colors for output
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================
# Helper functions
# ============================================================
log()     { echo -e "${GREEN}[*]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
err()     { echo -e "${RED}[x]${NC} $1"; }
info()    { echo -e "${BLUE}[i]${NC} $1"; }
section() { echo -e "\n${CYAN}========================================${NC}\n${CYAN}$1${NC}\n${CYAN}========================================${NC}\n"; }

# ============================================================
# Detect if we're running inside the Kali chroot or in Termux
# ============================================================
detect_context() {
    if [ -f /etc/os-release ] && grep -qi kali /etc/os-release 2>/dev/null; then
        echo "chroot"
    elif [ -n "${TERMUX_VERSION:-}" ] || [ -d /data/data/com.termux ] || uname -a | grep -qi termux; then
        echo "termux"
    else
        echo "unknown"
    fi
}

# ============================================================
# STEP 1: Setup Termux prerequisites (run this in Termux, not chroot)
# ============================================================
setup_termux() {
    section "STEP 1: Termux prerequisite setup"

    log "Updating Termux package list..."
    pkg update -y

    log "Upgrading existing packages..."
    pkg upgrade -y

    log "Installing wget and ca-certificates..."
    pkg install -y wget ca-certificates

    log "Setting up storage access..."
    termux-setup-storage

    # Get device IP for the optional scrcpy/TCP-ADB section
    log "Detecting device IP for TCP-ADB..."
    DEVICE_IP=$(ip -4 addr show wlan0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1)
    if [ -n "$DEVICE_IP" ]; then
        info "Device Wi-Fi IP: $DEVICE_IP"
    fi
}

# ============================================================
# STEP 2: Bootstrap the Kali chroot
# ============================================================
bootstrap_chroot() {
    section "STEP 2: Bootstrapping the Kali chroot"

    log "Downloading the official nethunter rootless installer (v20250525)..."
    wget -O install-nethunter-termux https://offs.ec/2MceZWr
    chmod +x install-nethunter-termux

    log "Running the installer (this takes ~15 minutes on Wi-Fi)..."
    log "Choose 'full' when prompted (~800 MB download, ~2.5 GB installed)"
    ./install-nethunter-termux
}

# ============================================================
# STEP 3: Fix the postgresql-18 wedge (run on the chroot, not Termux)
# ============================================================
fix_postgresql() {
    section "STEP 3: Fixing the postgresql-18 wedge"

    log "Removing wedged postgresql dpkg files..."
    rm -rf /var/lib/dpkg/info/postgresql* \
           /var/lib/dpkg/info/*postgresql* \
           /usr/lib/postgresql \
           /var/lib/postgresql \
           /var/log/postgresql \
           /var/cache/apt/archives/postgresql*.deb

    rm -f /var/lib/dpkg/triggers/File /var/lib/dpkg/triggers/Lock

    log "Re-configuring dpkg..."
    dpkg --configure -a 2>&1 | tail -3

    log "Fixing broken apt state..."
    apt --fix-broken install -y 2>&1 | tail -5
}

# ============================================================
# STEP 4: Fix the DNS inside the chroot
# ============================================================
fix_dns() {
    section "STEP 4: Fixing DNS inside the chroot"

    log "Writing nameservers to /etc/resolv.conf..."
    cat > /etc/resolv.conf <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 9.9.9.9
EOF

    log "Testing DNS resolution..."
    if ping -c 1 -W 2 http.kali.org >/dev/null 2>&1; then
        log "DNS works! http.kali.org is reachable."
    else
        warn "DNS test failed. Check your Wi-Fi connection."
    fi
}

# ============================================================
# STEP 5: Update the chroot
# ============================================================
update_chroot() {
    section "STEP 5: Updating the chroot"

    log "Running apt update..."
    apt update -y 2>&1 | tail -5

    log "Running apt full-upgrade..."
    apt full-upgrade -y 2>&1 | tail -5
}

# ============================================================
# STEP 6: Install offensive security tools
# ============================================================
install_tools() {
    section "STEP 6: Installing offensive security tools"

    log "Installing core offensive security packages..."
    apt install -y \
        nmap \
        msfconsole \
        sqlmap \
        aircrack-ng \
        wireshark \
        burpsuite \
        ffuf \
        gobuster \
        nikto \
        john \
        hydra \
        hashcat \
        responder \
        netcat-traditional \
        seclists \
        dirb \
        ncrack \
        wpscan \
        enum4linux \
        ldap-utils \
        smbclient \
        nbtscan \
        snmp \
        autopsy \
        sleuthkit \
        tcpdump \
        iptables \
        curl \
        wget \
        openssl \
        net-tools \
        iproute2 \
        curl \
        openssh-server \
        netcat-openbsd \
        2>&1 | tail -5
}

# ============================================================
# STEP 7: Install the Fluxbox desktop (the only working DE in proot 2026)
# ============================================================
install_desktop() {
    section "STEP 7: Installing the Fluxbox desktop"

    log "Installing Fluxbox + tools + terminal + icon theme + notifications..."
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
        notification-daemon \
        2>&1 | tail -5
}

# ============================================================
# STEP 8: Configure the Fluxbox canonical startup (fbpanel + tray + wallpaper)
# ============================================================
configure_fluxbox_startup() {
    section "STEP 8: Configuring Fluxbox startup"

    # Make sure the directory exists (the chroot uses /home/kali for user kali)
    mkdir -p /home/kali/.fluxbox

    log "Writing canonical ~/.fluxbox/startup (with fbpanel, stalonetray, conky, rofi)..."
    cat > /home/kali/.fluxbox/startup <<'FLUXEOF'
#!/bin/sh
# Fluxbox canonical startup — samsung-kali-nethunter-rootless
# Tested on S26 Ultra + beryllium. Works on any proot chroot on 2026+ Android.

# Wait for X to be ready
sleep 1

# Kill any zombies from previous sessions
pkill -f fbpanel 2>/dev/null
pkill -f stalonetray 2>/dev/null
pkill -f conky 2>/dev/null
pkill -f rofi 2>/dev/null

# System tray (must come before panel)
stalonetray --icon-size=16 --kludges=force_icons_size &

# Top panel with app menu, taskbar, clock
fbpanel &

# System info widget on the desktop
conky &

# Random Kali wallpaper
feh --bg-fill --randomize /usr/share/wallpapers/* 2>/dev/null &

# Notification daemon (so tray icons work properly)
notification-daemon &

# Auto-launch xfce4-terminal maximized
xfce4-terminal --maximize &

# Window manager must be last (exec replaces the shell)
exec fluxbox
FLUXEOF
    chmod +x /home/kali/.fluxbox/startup
    log "Startup file written: /home/kali/.fluxbox/startup"

    log "Configuring rofi for app launcher with icons..."
    mkdir -p /home/kali/.config/rofi
    cat > /home/kali/.config/rofi/config.rasi <<'ROFIEOF'
configuration {
    modi:        "drun,run,window";
    show-icons:  true;
    icon-theme:  "Adwaita";
}
ROFIEOF

    log "Binding Ctrl+Alt+R to rofi..."
    cat > /home/kali/.fluxbox/keys <<'KEYSEOF'
# samsung-kali-nethunter-rootless keybindings
# Ctrl+Alt+R opens rofi (app launcher)
Control Mod1 r :ExecCommand DISPLAY=:1 XAUTHORITY=/home/kali/.Xauthority rofi -show drun
# Ctrl+Alt+T opens a new terminal
Control Mod1 t :ExecCommand xfce4-terminal
KEYSEOF
    info "Press Ctrl+Alt+R in the desktop to launch rofi"
    info "Press Ctrl+Alt+T to open a new terminal"
}

# ============================================================
# STEP 9: Configure VNC (tigervnc) for KeX
# ============================================================
configure_vnc() {
    section "STEP 9: Configuring the VNC server"

    log "Writing the VNC xstartup to use Fluxbox..."
    cat > /etc/X11/Xtigervnc-session <<'VNCXEOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
exec dbus-launch --exit-with-session /home/kali/.fluxbox/startup
VNCXEOF
    chmod +x /etc/X11/Xtigervnc-session

    log "Setting the KeX VNC password..."
    mkdir -p /home/kali/.config/tigervnc
    if [ ! -f /home/kali/.config/tigervnc/passwd ]; then
        # Generate a random password (user can change it later with `nethunter kex passwd`)
        RANDOM_PASS=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 12)
        echo "$RANDOM_PASS" | vncpasswd -f > /home/kali/.config/tigervnc/passwd
        chmod 600 /home/kali/.config/tigervnc/passwd
        info "Generated random VNC password: $RANDOM_PASS"
        info "Change it later with: nethunter kex passwd"
    fi
}

# ============================================================
# STEP 10: Set the chroot home as root (since the bare Fluxbox xstartup launches as kali)
# ============================================================
fix_permissions() {
    section "STEP 10: Fixing file permissions"

    log "Ensuring Fluxbox files are owned by kali..."
    chown -R kali:kali /home/kali/.fluxbox 2>/dev/null || true
    chown -R kali:kali /home/kali/.config 2>/dev/null || true
}

# ============================================================
# STEP 11: Create the daily-use helper functions
# ============================================================
setup_aliases() {
    section "STEP 11: Setting up useful shell aliases (in Termux)"

    log "Adding helpful aliases to ~/.bashrc..."
    cat >> ~/.bashrc <<'BASHEOF'

# === samsung-kali-nethunter-rootless aliases ===
alias nh='nethunter'                  # drop into Kali chroot as user kali
alias nhr='nethunter -r'              # drop into Kali chroot as root
alias hack='nethunter -r'            # alias for nhr
alias kex='nethunter kex'             # configure VNC
alias kexstart='nethunter kex &amp;'   # start VNC server in background
alias kali='nethunter'               # alias for nh

# Show the current chroot status
alias nhstat='echo "=== Chroot status ===" &amp;&amp; nethunter -r "uname -a &amp;&amp; echo --- &amp;&amp; cat /etc/os-release | grep PRETTY &amp;&amp; echo --- &amp;&amp; dpkg-query -W | wc -l" &amp;&amp; echo "=== Tools ===" &amp;&amp; which nmap msfconsole sqlmap burpsuite wireshark 2>/dev/null'

# Quick app launchers
alias kali-nmap='nethunter -r nmap'
alias kali-msf='nethunter -r msfconsole'
alias kali-burp='nethunter -r burpsuite &amp;'
alias kali-wire='nethunter -r wireshark &amp;'
alias kali-fire='nethunter -r firefox-esr &amp;'
BASHEOF
    info "Aliases added. Type 'nh' to drop into Kali, 'kexstart' to start the desktop"
}

# ============================================================
# Main: detect context and run appropriate steps
# ============================================================
main() {
    echo
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   samsung-kali-nethunter-rootless installer            ║"
    echo "║   No root. No Knox trip. No warranty void.            ║"
    echo "║   Tested on Samsung Galaxy S26 Ultra (SM-S948B)       ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo

    CONTEXT=$(detect_context)
    info "Detected context: $CONTEXT"

    case "$CONTEXT" in
        termux)
            setup_termux
            bootstrap_chroot
            echo
            warn "Now drop into the chroot with: nethunter -r"
            warn "Then run this script again with: ./install.sh"
            warn "It will run the chroot-side steps automatically."
            ;;
        chroot)
            fix_postgresql
            fix_dns
            update_chroot
            install_tools
            install_desktop
            configure_fluxbox_startup
            configure_vnc
            fix_permissions
            echo
            log "Chroot setup complete!"
            echo
            info "Next steps:"
            info "  1. Exit the chroot: exit"
            info "  2. In Termux, start VNC: nethunter kex &amp;"
            info "  3. Open NetHunter KeX app on the phone → enter password"
            info "  4. The Fluxbox desktop with xfce4-terminal appears"
            info ""
            info "Optional — connect from your Mac:"
            info "  1. brew install scrcpy"
            info "  2. scrcpy                # see phone screen on your Mac"
            info "  3. adb tcpip 5555         # then 'adb connect IP:5555' for wireless"
            ;;
        *)
            err "Could not detect context. Run this script from inside Termux or the chroot."
            err "In Termux: pkg install wget &amp;&amp; wget -O install.sh ... &amp;&amp; bash install.sh"
            err "In chroot:  ./install.sh"
            exit 1
            ;;
    esac
}

main "$@"
