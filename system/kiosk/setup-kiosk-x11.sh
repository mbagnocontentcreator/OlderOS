#!/bin/bash
#
# OlderOS Kiosk Mode Setup Script (X11 + Openbox)
# Versione compatibile con VM e hardware datato
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}"
echo "╔══════════════════════════════════════════╗"
echo "║   OlderOS Kiosk Mode Setup (X11)         ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Errore: Esegui questo script come root (sudo)${NC}"
    exit 1
fi

OLDEROS_USER="${OLDEROS_USER:-olderos}"
OLDEROS_APP_PATH="${OLDEROS_APP_PATH:-/opt/olderos}"
OLDEROS_BINARY="olderos_launcher"

echo -e "${YELLOW}[1/7] Installazione dipendenze...${NC}"
apt-get update
apt-get install -y \
    xorg \
    openbox \
    libgtk-3-0 \
    libblkid1 \
    liblzma5 \
    fonts-noto-color-emoji \
    unclutter

echo -e "${YELLOW}[2/7] Creazione utente kiosk...${NC}"
if ! id "$OLDEROS_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$OLDEROS_USER"
    echo -e "${GREEN}Utente '$OLDEROS_USER' creato${NC}"
else
    echo -e "${GREEN}Utente '$OLDEROS_USER' esiste gia'${NC}"
fi

echo -e "${YELLOW}[3/7] Configurazione auto-login...${NC}"
mkdir -p /etc/systemd/system/getty@tty1.service.d/
cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $OLDEROS_USER --noclear %I \$TERM
EOF

echo -e "${YELLOW}[4/7] Configurazione .xinitrc...${NC}"
OLDEROS_HOME=$(eval echo ~$OLDEROS_USER)
cat > "$OLDEROS_HOME/.xinitrc" << EOF
#!/bin/bash

# Disabilita screensaver e risparmio energia
xset s off
xset -dpms
xset s noblank

# Nascondi cursore dopo 1 secondo di inattivita'
unclutter -idle 1 &

# Avvia OlderOS in fullscreen con Openbox
openbox --config-file $OLDEROS_HOME/.config/openbox/rc.xml &

# Attendi che Openbox sia pronto
sleep 1

# Avvia OlderOS
exec $OLDEROS_APP_PATH/$OLDEROS_BINARY
EOF
chmod +x "$OLDEROS_HOME/.xinitrc"
chown "$OLDEROS_USER:$OLDEROS_USER" "$OLDEROS_HOME/.xinitrc"

echo -e "${YELLOW}[5/7] Configurazione Openbox...${NC}"
mkdir -p "$OLDEROS_HOME/.config/openbox"
cat > "$OLDEROS_HOME/.config/openbox/rc.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance><strength>10</strength><screen_edge_strength>20</screen_edge_strength></resistance>
  <focus><focusNew>yes</focusNew><followMouse>no</followMouse></focus>
  <placement><policy>Smart</policy><center>yes</center></placement>
  <desktops><number>1</number></desktops>
  <keyboard>
    <!-- Disabilita shortcut che potrebbero uscire dall'app -->
  </keyboard>
  <mouse></mouse>
  <applications>
    <application class="*">
      <decor>no</decor>
      <fullscreen>yes</fullscreen>
      <maximized>yes</maximized>
    </application>
  </applications>
</openbox_config>
EOF
chown -R "$OLDEROS_USER:$OLDEROS_USER" "$OLDEROS_HOME/.config"

echo -e "${YELLOW}[6/7] Configurazione auto-start X...${NC}"
cat > "$OLDEROS_HOME/.bash_profile" << 'EOF'
# Auto-start X on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec startx
fi
EOF
chown "$OLDEROS_USER:$OLDEROS_USER" "$OLDEROS_HOME/.bash_profile"

echo -e "${YELLOW}[7/7] Creazione directory applicazione...${NC}"
mkdir -p "$OLDEROS_APP_PATH"
chown "$OLDEROS_USER:$OLDEROS_USER" "$OLDEROS_APP_PATH"

# Disabilita il display manager se presente
systemctl disable gdm 2>/dev/null || true
systemctl disable lightdm 2>/dev/null || true
systemctl disable sddm 2>/dev/null || true
systemctl set-default multi-user.target

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗"
echo "║     Setup completato!                    ║"
echo "╚══════════════════════════════════════════╝${NC}"
echo ""
echo "Prossimi passi:"
echo "1. Copia i file dell'app in: $OLDEROS_APP_PATH"
echo "   sudo cp -r build/linux/*/release/bundle/* $OLDEROS_APP_PATH/"
echo "   sudo chown -R $OLDEROS_USER:$OLDEROS_USER $OLDEROS_APP_PATH"
echo ""
echo "2. Riavvia il sistema:"
echo "   sudo reboot"
echo ""
echo "OlderOS partira' automaticamente all'avvio!"
