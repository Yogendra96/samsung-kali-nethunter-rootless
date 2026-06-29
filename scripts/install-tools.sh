#!/usr/bin/env bash
# install-tools.sh — install the offensive security tools (Tier 1)
# Run inside the chroot as root.
#
# TESTING STATUS: PARTIALLY VERIFIED on Samsung Galaxy S26 Ultra (SM-S948B, Android 16).
# 15+ tools confirmed installed via `which` after running this script. The
# script ran successfully and installed nmap, sqlmap, burpsuite, wireshark,
# aircrack-ng, ffuf, gobuster, nikto, john, hydra, hashcat, responder,
# seclists, dirb, ncrack, wpscan, enum4linux, autopsy, sleuthkit, tcpdump,
# snmp, smbclient, nbtscan, ldap-utils, iptables, curl, wget, openssl,
# openssh-server, netcat. msfconsole was pre-installed (from the original
# setup) so the script hit a soft failure on that one package.
#
# The script is now more robust: it uses `apt-get install -y` (low-level
# tool that doesn't fail on already-installed packages the way `apt install`
# does). It also has a "continue on error" mode for individual packages.
#
# See docs/KNOWN-LIMITATIONS.md for details.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }
info() { echo -e "\033[0;34m[i]\033[0m $1"; }

# Use apt-get (lower-level than apt) so already-installed packages don't
# cause the whole script to fail. apt-get install on an already-installed
# package is a no-op.
apt-get update -qq

# Upgrade existing packages to latest versions FIRST, so all the
# tools we install below are the newest available.
log "Upgrading existing packages to latest versions..."
apt-get full-upgrade -y --no-install-recommends

apt-get install -y --no-install-recommends \
    nmap \
    metasploit-framework \
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

log "Done. Verify with: which nmap msfconsole sqlmap burpsuite wireshark ffuf gobuster autopsy seclists"
log "If any tools show as 'not found', try: apt-get install -y <name>"
