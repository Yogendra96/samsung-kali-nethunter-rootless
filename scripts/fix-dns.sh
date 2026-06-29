#!/usr/bin/env bash
# fix-dns.sh — write public DNS to /etc/resolv.conf inside the chroot
# Run inside the chroot as root.
#
# Why this is needed: proot doesn't reliably inherit Android's DNS resolver.
# The chroot's /etc/resolv.conf is often empty or has an unresolvable
# nameserver. apt update / curl / nmap fail with "Temporary failure
# resolving".

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }

log "Writing public nameservers to /etc/resolv.conf..."
cat > /etc/resolv.conf <<'EOF'
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 9.9.9.9
EOF

log "Testing DNS resolution..."
if ping -c 1 -W 2 http.kali.org >/dev/null 2>&1; then
    log "DNS works! http.kali.org resolves."
else
    echo "[!] DNS test failed. Check your Wi-Fi connection."
    echo "[!] Also check that your phone's network is up: 'dumpsys connectivity' from Termux"
fi
