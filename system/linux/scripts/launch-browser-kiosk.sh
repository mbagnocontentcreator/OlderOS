#!/bin/bash
#
# OlderOS - Script per lanciare il browser in modalità kiosk
# Questo script viene chiamato dall'app Flutter per aprire videochiamate
#
# Uso: ./launch-browser-kiosk.sh <URL> [TITLE]
#

URL="$1"
TITLE="${2:-Videochiamata}"

# Verifica che sia stato fornito un URL
if [ -z "$URL" ]; then
    echo "Errore: URL non specificato"
    echo "Uso: $0 <URL> [TITLE]"
    exit 1
fi

# Funzione per trovare il browser disponibile
find_browser() {
    # Priorità: Firefox (migliore supporto WebRTC su Linux)
    if command -v firefox &> /dev/null; then
        echo "firefox"
        return 0
    fi

    # Chromium come alternativa
    if command -v chromium-browser &> /dev/null; then
        echo "chromium-browser"
        return 0
    fi

    if command -v chromium &> /dev/null; then
        echo "chromium"
        return 0
    fi

    # Google Chrome
    if command -v google-chrome &> /dev/null; then
        echo "google-chrome"
        return 0
    fi

    # Brave
    if command -v brave-browser &> /dev/null; then
        echo "brave-browser"
        return 0
    fi

    echo ""
    return 1
}

# Trova il browser
BROWSER=$(find_browser)

if [ -z "$BROWSER" ]; then
    echo "Errore: Nessun browser compatibile trovato"
    echo "Installa Firefox con: sudo apt install firefox"
    exit 1
fi

echo "Avvio $BROWSER in modalità kiosk per: $URL"

# Lancia il browser in base al tipo
case "$BROWSER" in
    firefox)
        # Firefox kiosk mode
        # --kiosk: modalità schermo intero senza UI browser
        # --new-window: apre in una nuova finestra
        firefox --kiosk --new-window "$URL" &
        ;;

    chromium-browser|chromium|google-chrome|brave-browser)
        # Chromium/Chrome kiosk mode
        # --kiosk: modalità schermo intero
        # --no-first-run: salta wizard iniziale
        # --disable-translate: disabilita popup traduzione
        # --disable-infobars: nasconde barre informative
        # --disable-features=TranslateUI: disabilita UI traduzione
        "$BROWSER" \
            --kiosk \
            --no-first-run \
            --disable-translate \
            --disable-infobars \
            --disable-features=TranslateUI \
            --app="$URL" &
        ;;

    *)
        # Fallback generico
        "$BROWSER" "$URL" &
        ;;
esac

# Salva il PID del browser
BROWSER_PID=$!
echo "Browser PID: $BROWSER_PID"

# Opzionale: aspetta che il browser si chiuda
# wait $BROWSER_PID

exit 0
