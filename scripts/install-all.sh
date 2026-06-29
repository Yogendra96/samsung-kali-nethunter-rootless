#!/usr/bin/env bash
# install-all.sh - runs all 3 tiers of the samsung-kali-nethunter-rootless install
# Designed to be run via: curl URL | bash
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
echo "Verify with: which nmap msfconsole nuclei ghidra spiderfoot pwntools"
