#!/bin/bash
#
# OlderOS Native Splash Screen
# Mostra un'immagine di splash mentre Flutter si avvia
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPLASH_IMAGE="$SCRIPT_DIR/splash.png"
PIDFILE="/tmp/olderos_splash.pid"

# Verifica che l'immagine esista
if [ ! -f "$SPLASH_IMAGE" ]; then
    exit 0
fi

# Ottieni dimensioni schermo
SCREEN_WIDTH=$(xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}' | cut -d'x' -f1)
SCREEN_HEIGHT=$(xdpyinfo 2>/dev/null | awk '/dimensions/{print $2}' | cut -d'x' -f2)

if [ -z "$SCREEN_WIDTH" ]; then
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080
fi

# Calcola posizione centrale per finestra 400x300
WIN_WIDTH=400
WIN_HEIGHT=300
POS_X=$(( (SCREEN_WIDTH - WIN_WIDTH) / 2 ))
POS_Y=$(( (SCREEN_HEIGHT - WIN_HEIGHT) / 2 ))

# Mostra splash con feh (se disponibile)
if command -v feh &> /dev/null; then
    feh --geometry ${WIN_WIDTH}x${WIN_HEIGHT}+${POS_X}+${POS_Y} \
        --borderless \
        --no-menus \
        --title "OlderOS" \
        "$SPLASH_IMAGE" &
    echo $! > "$PIDFILE"
# Fallback a display (ImageMagick)
elif command -v display &> /dev/null; then
    display -geometry +${POS_X}+${POS_Y} "$SPLASH_IMAGE" &
    echo $! > "$PIDFILE"
fi
