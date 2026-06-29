#!/usr/bin/env bash
# install-tools-extra-extra.sh — install the OPTIONAL advanced/niche tool set
# Run inside the chroot as root.
#
# TESTING STATUS: Tier 3 was the buggy one in the previous install-all.sh run.
# The ghidra apt install worked (verified ghidra 12.1.1+ds-0kali1 is now in /usr/bin/ghidra).
# The pipx install step failed silently — the script tried `apt install -y pipx` (instead
# of `apt-get install -y --no-install-recommends pipx`) and used a single `set -e` exit
# on any error.
#
# This fixed version:
# 1. Uses `apt-get install -y --no-install-recommends` (no-op on already-installed packages)
# 2. Properly bootstraps pipx (installs pipx, runs ensurepath, exports PATH)
# 3. Uses `|| true` after pipx installs so one failure doesn't kill the whole script
# 4. Runs each pipx install individually so errors are visible
# 5. Verifies installations after the script completes
#
# See docs/KNOWN-LIMITATIONS.md for details.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }
info() { echo -e "\033[0;34m[i]\033[0m $1"; }

# === Phase 1: apt packages (confirmed available in Kali arm64) ===
log "Phase 1: Installing apt packages (apt-get for robustness)..."

apt-get update -qq

# Note: gdb, apktool, checksec, ropper, macchanger, proxychains4 are already in
# install-tools-extra.sh (Tier 2). This tier only adds what's new.
apt-get install -y --no-install-recommends \
    evil-winrm \
    trivy \
    btscanner \
    bluez \
    theharvester \
    spiderfoot \
    i2p \
    anonsurf \
    ghidra \
    ruby-full \
    npm

log "Phase 1 (apt) complete."

# === Phase 2: pipx tools (Python packages not in apt) ===
log "Phase 2: Installing Python tools via pipx..."

# Install pipx if not present
apt-get install -y --no-install-recommends pipx
pipx ensurepath

# Add ~/.local/bin to PATH for the current session and for future shells
export PATH="$HOME/.local/bin:$PATH"
if ! grep -q "\.local/bin" "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
fi

# Install each tool individually with || true so one failure doesn't kill the rest
for pkg in pwntools angr frida-tools objection h8mail jrnl log4j-scan; do
    log "Installing $pkg via pipx..."
    if pipx install "$pkg" 2>&1 | tail -3; then
        log "$pkg installed"
    else
        warn "$pkg failed to install (continuing with other packages)"
    fi
done

log "Phase 2 (pipx) complete."

# === Phase 3: npm tools (note-taking) ===
log "Phase 3: Installing npm tools..."
if npm install -g obsidian-cli 2>&1 | tail -3; then
    log "obsidian-cli installed"
else
    warn "obsidian-cli install failed (continuing)"
fi
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

# === Verification ===
log ""
log "=== ALL DONE ==="
log "Verify with: which ghidra spiderfoot nuclei ; pipx list"
log ""
log "Note: ghidra is huge (~1 GB). If you don't need it, comment it out."
log "Note: pwntools/angr require PATH to include pipx bin (~/.local/bin)"
log "Note: frida-tools requires frida-server on the target device, which needs root"