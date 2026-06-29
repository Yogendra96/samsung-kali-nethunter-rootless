#!/usr/bin/env bash
# install-tools.sh — install the offensive security tools
# Run inside the chroot as root.
#
# TESTING STATUS: Structurally validated (bash syntax, package availability
# via `apt-cache policy`, no overlap with other tier scripts). NOT yet run
# end-to-end on a real device by the project author. See
# docs/KNOWN-LIMITATIONS.md for details. Please open an issue with any
# failures you encounter.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }

log "Installing offensive security tools (this may take 5-10 minutes)..."

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
    openssh-server \
    netcat-openbsd

log "Done. Verify with: which nmap msfconsole sqlmap burpsuite wireshark"
