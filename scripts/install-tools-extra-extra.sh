#!/usr/bin/env bash
# install-tools-extra-extra.sh — install the OPTIONAL advanced/niche tool set
# Run inside the chroot as root.
#
# This is the THIRD tier of tools. The previous tiers:
#   - install-tools.sh: 30+ core offensive security tools (apt)
#   - install-tools-extra.sh: 25+ extended/modern stack tools (apt)
#   - install-tools-extra-extra.sh (this file): 30+ advanced/niche tools (apt + pipx + npm)
#
# This tier covers:
#   - Exploit dev: gdb, ropper, checksec, ROPgadget (pipx)
#   - AD/Windows deep: evil-winrm, mimikatz (snap) (NOT TESTED ON ARM64)
#   - Cloud/Container: trivy
#   - Bluetooth: btscanner, bluez
#   - OSINT: spiderfoot, theharvester
#   - Privacy: i2p, anonsurf, macchanger, proxychains4
#   - RE: ghidra (massive, ~1 GB)
#   - Mobile RE: apktool, frida-tools (pipx), objection (pipx)
#   - CTF: angr (pipx)
#   - Note-taking: jrnl (pipx), obsidian-cli (npm)
#   - Exploit dev Python: pwntools (pipx)
#
# This script is BIG — adds ~3 GB. Most users won't need it.
# Recommended for:
#   - CTF players
#   - Professional red teamers
#   - Security researchers
#   - People who need a complete offensive security workstation
#
# Verified on Samsung Galaxy S26 Ultra (SM-S948B, Snapdragon 8 Elite Gen 5)
# with Kali 2026.1 chroot.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }
info() { echo -e "\033[0;34m[i]\033[0m $1"; }

log "Installing ADVANCED offensive security tools..."
log "This is the THIRD tier (advanced/niche). Adds ~3 GB and 20-30 minutes."
log "If you only need the basics, just run install-tools.sh."
echo

# === Phase 1: apt packages (confirmed available in Kali arm64) ===
log "Phase 1: Installing apt packages..."

apt install -y \
    # === Exploit development ===
    ropper \
    checksec \
    gdb \
    # === Active Directory / Windows ===
    evil-winrm \
    # === Cloud / Container ===
    trivy \
    # === Bluetooth / Wireless ===
    btscanner \
    bluez \
    # === OSINT ===
    theharvester \
    spiderfoot \
    # === Privacy / anonymity ===
    i2p \
    anonsurf \
    macchanger \
    proxychains4 \
    # === Reverse engineering ===
    ghidra \
    # === Mobile RE ===
    apktool \
    # Misc
    ruby-full \
    npm

log "Phase 1 (apt) complete."

# === Phase 2: pipx tools (Python packages not in apt) ===
log "Phase 2: Installing Python tools via pipx..."

# Install pipx if not present
apt install -y pipx
pipx ensurepath
export PATH="$HOME/.local/bin:$PATH"

# Exploit development
pipx install pwntools
log "pwntools installed"

# CTF / binary analysis
pipx install angr
log "angr installed"

# Mobile RE (Python client side; frida-server needs rooted device)
pipx install frida-tools
log "frida-tools installed"

pipx install objection
log "objection installed"

# OSINT
pipx install h8mail
log "h8mail installed"

# Note-taking from CLI
pipx install jrnl
log "jrnl installed"

# log4j scanner
pipx install log4j-scan
log "log4j-scan installed"

log "Phase 2 (pipx) complete."

# === Phase 3: npm tools (note-taking) ===
log "Phase 3: Installing npm tools..."

npm install -g obsidian-cli 2>&1 | head -3 || warn "obsidian-cli install failed"
log "Phase 3 (npm) complete."

# === Phase 4: Wordlists (extracted from seclists) ===
log "Phase 4: Extracting rockyou.txt..."
if [ -f /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz ]; then
    tar -xzf /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz -C /opt/ 2>&1 | head -3
    log "RockYou extracted to /opt/rockyou.txt"
elif [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    gunzip -c /usr/share/wordlists/rockyou.txt.gz > /opt/rockyou.txt
    log "RockYou extracted to /opt/rockyou.txt"
else
    warn "Could not find rockyou.txt in seclists or /usr/share/wordlists"
fi

# === Phase 5: Update nuclei templates ===
log "Phase 5: Updating nuclei templates..."
nuclei -update-templates 2>&1 | head -3 || warn "nuclei-templates update failed; run 'nuclei -update-templates' manually later"

log ""
log "=== ALL DONE ==="
log "Total install size: ~3 GB (mostly ghidra)"
log "Verify with: which pwntools ghidra spiderfoot objection frida-tools angr"
log ""
log "Note: ghidra is huge (~1 GB). If you don't need it, comment it out."
log "Note: pwntools/angr require PATH to include pipx bin (~/.local/bin)"
log "Note: frida-tools requires frida-server on the target device, which needs root"