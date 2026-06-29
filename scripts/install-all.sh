#!/usr/bin/env bash
# install-all.sh - runs all 3 tiers of the samsung-kali-nethunter-rootless install
# Designed to be run via: curl URL | bash
#
# ACTUALLY TESTED on Samsung Galaxy S26 Ultra (SM-S948B, Android 16) on 2026-06-29.
# Run from the chroot:
#   bash /root/install-all.sh
# Or fetch + run from the chroot in one command:
#   wget -qO /root/install-all.sh https://raw.githubusercontent.com/Yogendra96/samsung-kali-nethunter-rootless/main/scripts/install-all.sh ; bash /root/install-all.sh
#
# Test results from 2026-06-29:
# - Tier 1 (install-tools.sh): completed successfully
# - Tier 2 (install-tools-extra.sh): completed successfully
# - Tier 3 (install-tools-extra-extra.sh): apt installs completed;
#   pipx step failed silently (no pipx packages were installed).
#   impacket-scripts also errored. These need debugging.
# - Total tools verified installed: nmap, msfconsole, nuclei, spiderfoot
#   (plus ~30 others from Tier 1 + 23 from Tier 2)
set -e

echo "=== samsung-kali-nethunter-rootless - all-in-one installer ==="
echo "This will install 77+ tools across 3 tiers."
echo ""

# Update package list
apt-get update -qq

# Tier 1
echo ""
echo "=== Tier 1: Core offensive security tools ==="
bash <(curl -sSL https://raw.githubusercontent.com/Yogendra96/samsung-kali-nethunter-rootless/main/scripts/install-tools.sh)

# Tier 2
echo ""
echo "=== Tier 2: Extended tools (modern stack) ==="
bash <(curl -sSL https://raw.githubusercontent.com/Yogendra96/samsung-kali-nethunter-rootless/main/scripts/install-tools-extra.sh)

# Tier 3
echo ""
echo "=== Tier 3: Advanced/niche tools ==="
bash <(curl -sSL https://raw.githubusercontent.com/Yogendra96/samsung-kali-nethunter-rootless/main/scripts/install-tools-extra-extra.sh)

echo ""
echo "=== ALL TIERS COMPLETE ==="
echo "Showing your finished Kali chroot system info..."
fastfetch --logo small 2>/dev/null || fastfetch 2>/dev/null || echo "fastfetch not available"
echo ""
echo "Verify with: which nmap msfconsole nuclei ghidra spiderfoot pwntools"
