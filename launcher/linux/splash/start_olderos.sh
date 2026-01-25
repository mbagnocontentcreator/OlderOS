#!/bin/bash
#
# OlderOS Launcher con Splash Screen nativo
# Questo script mostra uno splash mentre Flutter si avvia
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/opt/olderos"

# Mostra lo splash screen
"$SCRIPT_DIR/show_splash.sh" &

# Avvia OlderOS
exec "$INSTALL_DIR/olderos_launcher"
