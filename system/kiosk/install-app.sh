#!/bin/bash
#
# OlderOS App Installation Script
# Installa l'applicazione OlderOS nella directory kiosk
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

OLDEROS_APP_PATH="${OLDEROS_APP_PATH:-/opt/olderos}"
BUNDLE_PATH="$1"

echo -e "${GREEN}OlderOS App Installer${NC}"
echo ""

# Verifica argomenti
if [ -z "$BUNDLE_PATH" ]; then
    echo "Uso: $0 <percorso-bundle>"
    echo ""
    echo "Esempio:"
    echo "  $0 ~/OlderOS/launcher/build/linux/arm64/release/bundle"
    echo "  $0 ./olderos-launcher-linux"
    exit 1
fi

# Verifica se eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Errore: Esegui questo script come root (sudo)${NC}"
    exit 1
fi

# Verifica che il bundle esista
if [ ! -d "$BUNDLE_PATH" ]; then
    echo -e "${RED}Errore: Directory bundle non trovata: $BUNDLE_PATH${NC}"
    exit 1
fi

# Verifica che il binario esista
if [ ! -f "$BUNDLE_PATH/olderos_launcher" ]; then
    echo -e "${RED}Errore: Binario olderos_launcher non trovato in $BUNDLE_PATH${NC}"
    exit 1
fi

echo -e "${YELLOW}Installazione app in $OLDEROS_APP_PATH...${NC}"

# Pulisci installazione precedente
rm -rf "$OLDEROS_APP_PATH"/*

# Copia i file
cp -r "$BUNDLE_PATH"/* "$OLDEROS_APP_PATH/"

# Imposta permessi
chmod +x "$OLDEROS_APP_PATH/olderos_launcher"
chown -R olderos:olderos "$OLDEROS_APP_PATH" 2>/dev/null || true

echo ""
echo -e "${GREEN}Installazione completata!${NC}"
echo ""
echo "Per avviare OlderOS in kiosk mode, riavvia il sistema:"
echo "  sudo reboot"
