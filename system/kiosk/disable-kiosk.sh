#!/bin/bash
#
# OlderOS Kiosk Mode Disable Script
# Disabilita il kiosk mode e ripristina il desktop normale
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}Disabilitazione OlderOS Kiosk Mode...${NC}"

# Verifica se eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Errore: Esegui questo script come root (sudo)${NC}"
    exit 1
fi

# Disabilita il servizio kiosk
systemctl disable olderos-kiosk.service 2>/dev/null || true
systemctl stop olderos-kiosk.service 2>/dev/null || true

# Rimuovi auto-login
rm -f /etc/systemd/system/getty@tty1.service.d/autologin.conf

# Ricarica systemd
systemctl daemon-reload

echo ""
echo -e "${GREEN}Kiosk mode disabilitato!${NC}"
echo ""
echo "Al prossimo riavvio il sistema partira' normalmente."
echo "Per riattivare: sudo systemctl enable olderos-kiosk.service"
