#!/usr/bin/env bash
#
# control-from-mac.sh — control the Android device from your Mac
# Companion to the main install script. Run on the Mac, not on the phone.
#
# What this does:
#   1. Installs scrcpy (screen mirroring + keyboard/mouse control)
#   2. Installs adb (already there if you've used Android dev tools)
#   3. Walks you through USB debugging setup
#   4. Sets up TCP/IP ADB so you can connect wirelessly
#   5. Provides a menu of remote-control options:
#       - scrcpy for screen mirroring
#       - adb shell for terminal access
#       - adb input text for typing into phone apps
#       - adb push/pull for file transfer
#
# Usage:
#   ./control-from-mac.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[*]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[x]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }
ask()  { echo -ne "${CYAN}?${NC} $1 "; }

# ============================================================
# Step 1: Install adb + scrcpy via Homebrew
# ============================================================
install_tools() {
    log "Checking for adb..."
    if ! command -v adb >/dev/null 2>&1; then
        log "Installing adb via Homebrew..."
        brew install android-platform-tools
    else
        info "adb already installed: $(adb --version | head -1)"
    fi

    log "Checking for scrcpy..."
    if ! command -v scrcpy >/dev/null 2>&1; then
        log "Installing scrcpy via Homebrew..."
        brew install scrcpy
    else
        info "scrcpy already installed: $(scrcpy --version | head -1)"
    fi
}

# ============================================================
# Step 2: Verify the device is connected
# ============================================================
verify_device() {
    log "Checking for connected Android device..."

    if ! adb devices | grep -q "device$"; then
        err "No Android device found over USB."
        echo
        info "Troubleshooting:"
        info "  1. Enable Developer Options on the phone:"
        info "     Settings → About Phone → Software Information → tap Build Number 7 times"
        info "  2. Enable USB Debugging:"
        info "     Settings → Developer Options → USB Debugging: ON"
        info "  3. Set USB config to File Transfer (not just charging):"
        info "     Settings → Developer Options → Default USB Configuration → File Transfer"
        info "  4. Plug the phone into the Mac via USB-C"
        info "  5. Accept the 'Allow USB debugging?' popup on the phone"
        echo
        info "On Samsung phones, also turn OFF Auto Blocker:"
        info "     Settings → Device Care → Auto Blocker → OFF"
        echo
        ask "Try again? (y/n)"
        read -r ans
        if [[ "$ans" == "y" ]]; then
            verify_device
        else
            exit 1
        fi
    fi

    SERIAL=$(adb devices | awk 'NR>1 && $2=="device" {print $1}' | head -1)
    info "Connected device: $SERIAL"
}

# ============================================================
# Step 3: Show device info
# ============================================================
show_device_info() {
    echo
    log "Device information:"
    echo "  Model:      $(adb -d shell getprop ro.product.model 2>/dev/null)"
    echo "  Android:    $(adb -d shell getprop ro.build.version.release 2>/dev/null)"
    echo "  Security:   $(adb -d shell getprop ro.build.version.security_patch 2>/dev/null)"
    echo "  Firmware:   $(adb -d shell getprop ro.build.fingerprint 2>/dev/null | cut -c1-80)..."
    echo "  Serial:     $(adb -d shell getprop ro.serialno 2>/dev/null)"
    echo "  Knox e-fuse: $(adb -d shell getprop ro.boot.warranty_bit 2>/dev/null) (0x0000 = virgin)"
    echo
}

# ============================================================
# Step 4: Set up TCP ADB (wireless ADB)
# ============================================================
setup_tcp_adb() {
    log "Setting up wireless (TCP) ADB..."

    # Get the device's Wi-Fi IP
    DEVICE_IP=$(adb -d shell "ip -4 addr show wlan0 2>/dev/null | grep -oP 'inet \K[\d.]+' | head -1" 2>/dev/null | tr -d '\r')

    if [ -z "$DEVICE_IP" ]; then
        warn "Could not get device IP. Make sure the phone is on Wi-Fi."
        return 1
    fi

    info "Phone Wi-Fi IP: $DEVICE_IP"
    log "Enabling TCP ADB on port 5555..."
    adb -d tcpip 5555

    sleep 2

    log "Connecting to $DEVICE_IP:5555..."
    if adb connect "$DEVICE_IP:5555" 2>&1 | grep -q "connected"; then
        log "Connected wirelessly!"
        info "You can now unplug the USB cable."
        info "To reconnect later: adb connect $DEVICE_IP:5555"
    else
        warn "Wireless connection failed. Stick with USB for now."
    fi
}

# ============================================================
# Step 5: Launch scrcpy (the main way to control the phone)
# ============================================================
launch_scrcpy() {
    log "Launching scrcpy (phone screen on your Mac)..."
    info "Press Ctrl+C in this terminal to stop scrcpy."
    info "Useful scrcpy keyboard shortcuts (work when scrcpy window is focused):"
    info "  Cmd+S       toggle fullscreen"
    info "  Cmd+H       toggle hide mouse cursor"
    info "  Cmd+P       toggle power button (lock/unlock phone)"
    info "  Cmd+B       toggle back button"
    info "  Cmd+M       toggle menu button"
    info "  Cmd+O       turn phone screen off (saves battery)"
    info "  Cmd+Shift+O turn phone screen back on"
    info "  Right-click  Android back button"
    echo
    scrcpy
}

# ============================================================
# Step 6: Run an adb shell into the device
# ============================================================
run_adb_shell() {
    log "Opening adb shell (Ctrl+D or 'exit' to close)..."
    adb -d shell
}

# ============================================================
# Step 7: Send a quick keystroke or text
# ============================================================
send_text() {
    ask "Text to type into the focused app on the phone:"
    read -r text
    log "Typing: $text"
    adb -d shell input text "$text"
    info "Text sent. The text appears in whatever app is currently focused on the phone."
}

# ============================================================
# Main menu loop
# ============================================================
main() {
    echo
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║   samsung-kali-nethunter-rootless                     ║"
    echo "║   Mac-side controller (scrcpy + adb)                   ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo

    install_tools
    verify_device
    show_device_info

    while true; do
        echo
        echo "What do you want to do?"
        echo
        echo "  1. Launch scrcpy (mirror phone screen to Mac)"
        echo "  2. Open adb shell (terminal access to phone)"
        echo "  3. Send a text string to the focused app"
        echo "  4. Set up wireless (TCP) ADB — disconnect USB after"
        echo "  5. Show device info again"
        echo "  6. Take a screenshot of the phone"
        echo "  7. Install APKs from this Mac to the phone"
        echo "  8. Pull a file from the phone to this Mac"
        echo "  9. Push a file from this Mac to the phone"
        echo "  0. Quit"
        echo
        ask "Choice:"
        read -r choice

        case "$choice" in
            1) launch_scrcpy ;;
            2) run_adb_shell ;;
            3) send_text ;;
            4) setup_tcp_adb ;;
            5) show_device_info ;;
            6)
                log "Taking screenshot..."
                adb -d shell screencap -p /sdcard/screenshot.png
                adb -d pull /sdcard/screenshot.png ./phone-screenshot-$(date +%Y%m%d-%H%M%S).png
                log "Saved to current directory."
                ;;
            7)
                ask "Path to APK file:"
                read -r apk
                if [ -f "$apk" ]; then
                    adb -d install "$apk"
                else
                    err "File not found: $apk"
                fi
                ;;
            8)
                ask "Remote path on phone:"
                read -r rpath
                ask "Local path to save to:"
                read -r lpath
                adb -d pull "$rpath" "$lpath"
                ;;
            9)
                ask "Local file path:"
                read -r lpath
                ask "Remote destination on phone:"
                read -r rpath
                adb -d push "$lpath" "$rpath"
                ;;
            0) log "Goodbye."; exit 0 ;;
            *) warn "Invalid choice." ;;
        esac
    done
}

main "$@"
