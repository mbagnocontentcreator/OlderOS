#!/bin/bash
#
# Crea l'immagine splash per OlderOS
# Richiede ImageMagick (convert)
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/splash.png"
EMOJI_SOURCE="$SCRIPT_DIR/../../assets/images/elderly_emoji.png"

# Se ImageMagick è disponibile, crea lo splash
if command -v convert &> /dev/null && [ -f "$EMOJI_SOURCE" ]; then
    # Crea sfondo gradiente blu con logo e testo
    convert -size 400x300 \
        -define gradient:angle=180 \
        gradient:'#E8F4FD-#FFFFFF' \
        \( "$EMOJI_SOURCE" -resize 100x100 \) -gravity center -geometry +0-40 -composite \
        -gravity center -pointsize 36 -font "Ubuntu-Bold" -fill '#1A1A2E' \
        -annotate +0+60 'OlderOS' \
        -gravity south -pointsize 14 -fill '#666666' \
        -annotate +0+20 'Caricamento in corso...' \
        "$OUTPUT"
    echo "Splash creato: $OUTPUT"
else
    # Crea uno splash semplice senza ImageMagick
    # (copia l'emoji come fallback)
    if [ -f "$EMOJI_SOURCE" ]; then
        cp "$EMOJI_SOURCE" "$OUTPUT"
        echo "Splash fallback creato: $OUTPUT"
    else
        echo "Impossibile creare splash: manca ImageMagick o l'immagine sorgente"
    fi
fi
