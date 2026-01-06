#!/bin/bash
#
# OlderOS - Script di installazione dipendenze
# Eseguire con: sudo ./install-dependencies.sh
#

echo "=========================================="
echo "   OlderOS - Installazione Dipendenze    "
echo "=========================================="
echo ""

# Verifica che sia eseguito come root
if [ "$EUID" -ne 0 ]; then
    echo "Errore: Eseguire come root (sudo)"
    exit 1
fi

# Rileva il package manager
if command -v apt-get &> /dev/null; then
    PKG_MANAGER="apt"
elif command -v dnf &> /dev/null; then
    PKG_MANAGER="dnf"
elif command -v pacman &> /dev/null; then
    PKG_MANAGER="pacman"
else
    echo "Errore: Package manager non supportato"
    exit 1
fi

echo "Package manager rilevato: $PKG_MANAGER"
echo ""

# Installa Firefox (necessario per videochiamate)
echo "[1/4] Installazione Firefox..."
case "$PKG_MANAGER" in
    apt)
        apt-get update
        apt-get install -y firefox
        ;;
    dnf)
        dnf install -y firefox
        ;;
    pacman)
        pacman -S --noconfirm firefox
        ;;
esac

# Installa dipendenze Flutter per Linux
echo "[2/4] Installazione dipendenze Flutter..."
case "$PKG_MANAGER" in
    apt)
        apt-get install -y \
            clang \
            cmake \
            ninja-build \
            pkg-config \
            libgtk-3-dev \
            liblzma-dev \
            libstdc++-12-dev \
            libwebkit2gtk-4.1-dev
        ;;
    dnf)
        dnf install -y \
            clang \
            cmake \
            ninja-build \
            gtk3-devel \
            webkit2gtk4.1-devel
        ;;
    pacman)
        pacman -S --noconfirm \
            clang \
            cmake \
            ninja \
            gtk3 \
            webkit2gtk-4.1
        ;;
esac

# Installa Openbox per modalità kiosk
echo "[3/4] Installazione Openbox (kiosk mode)..."
case "$PKG_MANAGER" in
    apt)
        apt-get install -y openbox xorg
        ;;
    dnf)
        dnf install -y openbox xorg-x11-server-Xorg
        ;;
    pacman)
        pacman -S --noconfirm openbox xorg-server xorg-xinit
        ;;
esac

# Installa utilità aggiuntive
echo "[4/4] Installazione utilità..."
case "$PKG_MANAGER" in
    apt)
        apt-get install -y \
            unclutter \
            xdotool \
            pulseaudio \
            alsa-utils
        ;;
    dnf)
        dnf install -y \
            unclutter \
            xdotool \
            pulseaudio \
            alsa-utils
        ;;
    pacman)
        pacman -S --noconfirm \
            unclutter \
            xdotool \
            pulseaudio \
            alsa-utils
        ;;
esac

echo ""
echo "=========================================="
echo "   Installazione completata!             "
echo "=========================================="
echo ""
echo "Browser installati:"
command -v firefox && echo "  - Firefox: $(firefox --version 2>/dev/null || echo 'installato')"
command -v chromium-browser && echo "  - Chromium: installato"
echo ""
echo "Prossimi passi:"
echo "  1. Configura Openbox per avvio automatico"
echo "  2. Compila OlderOS con: flutter build linux --release"
echo "  3. Copia l'app in /opt/olderos/"
echo ""
