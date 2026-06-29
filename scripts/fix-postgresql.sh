#!/usr/bin/env bash
# fix-postgresql.sh — nuclear fix for the wedged postgresql-18 package
# Run inside the chroot as root.
#
# Why this is needed: postgresql-18's prerm script tries to start the
# postgres service, which can't run in proot. This blocks ALL apt installs.
#
# This script removes the dpkg records for postgresql packages so apt
# can reinstall them cleanly.

set -euo pipefail

log()  { echo -e "\033[0;32m[*]\033[0m $1"; }
warn() { echo -e "\033[1;33m[!]\033[0m $1"; }

log "Removing wedged postgresql dpkg files..."
rm -rf /var/lib/dpkg/info/postgresql* \
       /var/lib/dpkg/info/*postgresql* \
       /usr/lib/postgresql \
       /var/lib/postgresql \
       /var/log/postgresql \
       /var/cache/apt/archives/postgresql*.deb

rm -f /var/lib/dpkg/triggers/File /var/lib/dpkg/triggers/Lock

log "Re-configuring dpkg..."
dpkg --configure -a

log "Fixing broken apt state..."
apt --fix-broken install -y

log "Done. Future apt installs should work now."
warn "If you want to silence the postgresql warnings entirely, run:"
warn "  apt-mark hold postgresql-18 postgresql-18-jit"
