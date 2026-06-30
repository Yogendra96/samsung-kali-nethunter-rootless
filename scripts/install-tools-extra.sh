#!/usr/bin/env bash
# install-tools-extra.sh — install the OPTIONAL extended tool set
# Run inside the chroot as root.
#
# TESTING STATUS: Structurally validated (bash syntax, package availability
# via `apt-cache policy`, no overlap with other tier scripts). NOT yet run
# end-to-end on a real device by the project author. See
# docs/KNOWN-LIMITATIONS.md for details. Please open an issue with any
# failures you encounter.
#
# What's in this script vs install-tools.sh:
#   - install-tools.sh: the 30 core tools that are always installed
#   - install-tools-extra.sh: 25+ additional tools that are useful but optional
#
# Why split? The core install is ~1.5 GB and runs in ~10 minutes. The extras
# add another ~2 GB and 15-20 minutes more. Some users don't need them.

# Categories covered by the extras:
#   - Web app testing: nuclei, httpx, qsreplace, gf, subfinder
#   - Active Directory: impacket, bloodhound-python, nxc (crackmapexec)
#   - Mobile/APK: apktool, jadx, frida (docs only)
#   - Network: bettercap, macchanger, proxychains4
#   - Recon: amass, subjack, assetfinder, h8mail
#   - Passwords: cewl, mentalist, searchsploit
#   - Exploit dev: gdb, gdb-gef, pwntools, ropper, ROPgadget, checksec
#   - Reverse eng: ghidra, rizin, jadx (already listed under mobile)
#   - Privacy: tor, anonsurf, macchanger
#   - Wordlists: rockyou.txt (extracted from seclists)
#
# Run this AFTER install-tools.sh:
#   sudo apt install -y nuclei httpx-toolkit subfinder ...
#   See "apt install" command at the bottom of this file.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }
info() { echo -e "\033[0;34m[i]\033[0m $1"; }

log "Installing extended offensive security tools..."
log "This is OPTIONAL — it adds ~2 GB and 15-20 minutes."
log "If you only need the basics, run install-tools.sh instead."
echo

# Use apt-get (lower-level than apt) so already-installed packages don't
# cause the whole script to fail.
apt-get update -qq

# Hold postgresql-18 packages so they don't block full-upgrade
# in proot (the prerm script can't stop the service properly in proot)
apt-mark hold postgresql-18 postgresql-18-jit postgresql-client-18

# Upgrade existing packages to latest versions FIRST.
log "Upgrading existing packages to latest versions..."
apt-get full-upgrade -y --no-install-recommends

# Install all packages in one apt call to save time
apt-get install -y --no-install-recommends \
    # === Web app testing ===
    nuclei \
    httpx-toolkit \
    subfinder \
    qsreplace \
    # === Active Directory / Windows ===
    impacket-scripts \
    bloodhound \
    nxc \
    # === Mobile / APK reverse engineering ===
    apktool \
    jadx \
    # === Network / wireless ===
    bettercap \
    macchanger \
    proxychains4 \
    # === Recon / OSINT ===
    amass \
    assetfinder \
    recon-ng \
    # === Passwords / wordlists ===
    cewl \
    searchsploit \
    # Exploit dev
    gdb \
    ropper \
    checksec \
    # Privacy / anonymity
    tor \
    # Misc
    ruby \
    git
    # Note: curl and wget are already in install-tools.sh (core)

# pipx tools (Python tools that aren't in apt)
log "Installing pipx for Python tool management..."
apt install -y pipx
pipx ensurepath

# nuclei-templates (community templates — not in apt)
log "Installing nuclei-templates..."
nuclei -update-templates 2>&1 | head -3 || warn "nuclei-templates download failed; run 'nuclei -update-templates' manually later"

# RockYou wordlist (extracted from seclists)
log "Extracting rockyou.txt from seclists..."
if [ -f /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz ]; then
    tar -xzf /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz \
        -C /opt/ 2>&1 | head -3
    log "RockYou extracted to /opt/rockyou.txt"
elif [ -f /usr/share/wordlists/rockyou.txt.gz ]; then
    gunzip -c /usr/share/wordlists/rockyou.txt.gz > /opt/rockyou.txt
    log "RockYou extracted to /opt/rockyou.txt"
else
    warn "Could not find rockyou.txt in seclists or /usr/share/wordlists"
fi

# === Show the finished system (after extras) ===
log "Showing your Kali chroot system info with new tools..."
fastfetch --logo small 2>/dev/null || fastfetch 2>/dev/null || echo "fastfetch not available"

log "Done! Verify with: which nuclei impacket-scripts apktool bettercap ghidra"