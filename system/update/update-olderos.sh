#!/bin/bash
#
# OlderOS Update Script
# Aggiorna l'app OlderOS scaricando le ultime modifiche da GitHub
#

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

REPO_DIR="$HOME/OlderOS"
LAUNCHER_DIR="$REPO_DIR/launcher"
INSTALL_DIR="/opt/olderos"

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}   OlderOS - Aggiornamento     ${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

# Verifica che il repo esista
if [ ! -d "$LAUNCHER_DIR" ]; then
    echo -e "${RED}Errore: Repository non trovato in $REPO_DIR${NC}"
    echo "Clona prima il repository con:"
    echo "  git clone https://github.com/mbagnocontentcreator/OlderOS.git ~/OlderOS"
    exit 1
fi

cd "$LAUNCHER_DIR"

# Salva la versione corrente
OLD_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
echo -e "${YELLOW}Versione attuale: $OLD_COMMIT${NC}"

# Scarica aggiornamenti
echo ""
echo "Scaricamento aggiornamenti..."
git fetch origin main

# Verifica se ci sono aggiornamenti
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    echo -e "${GREEN}Il sistema e' gia' aggiornato!${NC}"
    exit 0
fi

# Applica aggiornamenti
echo "Applicazione aggiornamenti..."
git pull origin main

NEW_COMMIT=$(git rev-parse --short HEAD)
echo -e "${GREEN}Nuova versione: $NEW_COMMIT${NC}"

# Mostra cosa e' cambiato
echo ""
echo "Modifiche:"
git log --oneline "$OLD_COMMIT..$NEW_COMMIT" | head -10

# Aggiorna dipendenze
echo ""
echo "Aggiornamento dipendenze Flutter..."
flutter pub get

# Compila
echo ""
echo "Compilazione in corso... (potrebbe richiedere qualche minuto)"
flutter build linux --release

# Determina architettura
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    BUILD_DIR="build/linux/arm64/release/bundle"
else
    BUILD_DIR="build/linux/x64/release/bundle"
fi

# Verifica che la build sia andata a buon fine
if [ ! -f "$BUILD_DIR/olderos_launcher" ]; then
    echo -e "${RED}Errore: Build fallita${NC}"
    exit 1
fi

# Installa
echo ""
echo "Installazione in $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo cp -r "$BUILD_DIR" "$INSTALL_DIR"
sudo chmod +x "$INSTALL_DIR/olderos_launcher"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}   Aggiornamento completato!   ${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Versione: $OLD_COMMIT -> $NEW_COMMIT"
echo ""
echo "Per applicare le modifiche:"
echo "  - Se sei in Kiosk Mode: sudo reboot"
echo "  - Altrimenti: riavvia l'app"
echo ""

# Chiedi se riavviare
read -p "Vuoi riavviare ora? (s/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Ss]$ ]]; then
    echo "Riavvio in corso..."
    sudo reboot
fi
