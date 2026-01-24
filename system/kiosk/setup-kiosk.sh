#!/bin/bash
#
# OlderOS Kiosk Mode Setup Script
# Configura Linux per avviare OlderOS automaticamente all'avvio
#

set -e

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║     OlderOS Kiosk Mode Setup             ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# Verifica se eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Errore: Esegui questo script come root (sudo)${NC}"
    exit 1
fi

# Variabili
OLDEROS_USER="${OLDEROS_USER:-olderos}"
OLDEROS_APP_PATH="${OLDEROS_APP_PATH:-/opt/olderos}"
OLDEROS_BINARY="olderos_launcher"

echo -e "${YELLOW}[1/6] Installazione dipendenze...${NC}"
apt-get update
apt-get install -y \
    cage \
    libgtk-3-0 \
    libblkid1 \
    liblzma5 \
    fonts-noto-color-emoji \
    plymouth \
    plymouth-themes

echo -e "${YELLOW}[2/6] Creazione utente kiosk...${NC}"
if ! id "$OLDEROS_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$OLDEROS_USER"
    echo -e "${GREEN}Utente '$OLDEROS_USER' creato${NC}"
else
    echo -e "${GREEN}Utente '$OLDEROS_USER' esiste gia'${NC}"
fi

echo -e "${YELLOW}[3/6] Configurazione auto-login...${NC}"
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $OLDEROS_USER --noclear %I \$TERM
EOF

echo -e "${YELLOW}[4/6] Creazione servizio systemd per OlderOS...${NC}"
cat > /etc/systemd/system/olderos-kiosk.service << EOF
[Unit]
Description=OlderOS Kiosk Mode
After=systemd-user-sessions.service plymouth-quit-wait.service
After=getty@tty1.service

[Service]
Type=simple
User=$OLDEROS_USER
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=WLR_LIBINPUT_NO_DEVICES=1
PAMName=login
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
TTYVTDisallocate=yes
StandardInput=tty-fail
StandardOutput=journal
StandardError=journal
ExecStart=/usr/bin/cage -s -- $OLDEROS_APP_PATH/$OLDEROS_BINARY
Restart=always
RestartSec=3

[Install]
WantedBy=graphical.target
EOF

echo -e "${YELLOW}[5/6] Configurazione avvio grafico...${NC}"
systemctl set-default graphical.target
systemctl enable olderos-kiosk.service

echo -e "${YELLOW}[6/6] Creazione directory applicazione...${NC}"
mkdir -p "$OLDEROS_APP_PATH"
chown "$OLDEROS_USER:$OLDEROS_USER" "$OLDEROS_APP_PATH"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗"
echo "║     Setup completato!                    ║"
echo "╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Prossimi passi:"
echo "1. Copia i file dell'app in: $OLDEROS_APP_PATH"
echo "   sudo cp -r build/linux/*/release/bundle/* $OLDEROS_APP_PATH/"
echo ""
echo "2. Riavvia il sistema:"
echo "   sudo reboot"
echo ""
echo "OlderOS partira' automaticamente all'avvio!"
