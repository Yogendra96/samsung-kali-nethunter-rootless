#!/usr/bin/env bash
# install-tools.sh — install the offensive security tools
# Run inside the chroot as root.

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
