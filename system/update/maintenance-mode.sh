#!/bin/bash
#
# OlderOS Maintenance Mode
# Entra/esci dalla modalità manutenzione (disabilita temporaneamente kiosk)
#

ACTION="${1:-toggle}"

KIOSK_USER="olderos"
AUTOSTART_FILE="/home/$KIOSK_USER/.config/openbox/autostart"
AUTOSTART_BACKUP="/home/$KIOSK_USER/.config/openbox/autostart.backup"

case "$ACTION" in
    on|enable|enter)
        echo "Entrando in modalità manutenzione..."

        # Backup dell'autostart
        if [ -f "$AUTOSTART_FILE" ]; then
            sudo cp "$AUTOSTART_FILE" "$AUTOSTART_BACKUP"
            # Sostituisci con un terminale
            sudo bash -c "cat > $AUTOSTART_FILE << 'EOF'
# Maintenance Mode - Terminal
xterm -fa 'Monospace' -fs 14 -fg white -bg black -e bash &
EOF"
        fi

        echo "Modalità manutenzione attivata."
        echo "Al prossimo riavvio avrai accesso al terminale."
        echo ""
        echo "Per aggiornare OlderOS, esegui:"
        echo "  ~/OlderOS/system/update/update-olderos.sh"
        echo ""
        echo "Per tornare al Kiosk Mode:"
        echo "  ~/OlderOS/system/update/maintenance-mode.sh off"
        ;;

    off|disable|exit)
        echo "Uscendo dalla modalità manutenzione..."

        # Ripristina l'autostart originale
        if [ -f "$AUTOSTART_BACKUP" ]; then
            sudo cp "$AUTOSTART_BACKUP" "$AUTOSTART_FILE"
            echo "Kiosk Mode ripristinato."
        else
            # Ricrea l'autostart del kiosk (con splash nativo)
            sudo bash -c "cat > $AUTOSTART_FILE << 'EOF'
# OlderOS Kiosk Mode
unclutter -idle 1 &
# Mostra splash nativo mentre Flutter si avvia
if [ -f /opt/olderos/splash/show_splash.sh ]; then
    /opt/olderos/splash/show_splash.sh &
fi
/opt/olderos/olderos_launcher &
EOF"
            echo "Kiosk Mode configurato."
        fi

        echo "Al prossimo riavvio tornerai in Kiosk Mode."
        ;;

    status)
        if grep -q "olderos_launcher" "$AUTOSTART_FILE" 2>/dev/null; then
            echo "Stato: KIOSK MODE"
        else
            echo "Stato: MAINTENANCE MODE"
        fi
        ;;

    *)
        echo "Uso: $0 {on|off|status}"
        echo ""
        echo "  on     - Entra in modalità manutenzione (terminale al riavvio)"
        echo "  off    - Torna al Kiosk Mode"
        echo "  status - Mostra lo stato attuale"
        ;;
esac
