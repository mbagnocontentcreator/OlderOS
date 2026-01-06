#!/bin/bash
#
# OlderOS - Autostart per Openbox
# Questo script viene eseguito all'avvio di Openbox
#
# Copiare in: ~/.config/openbox/autostart
#

# Nascondi il cursore dopo 3 secondi di inattività
unclutter -idle 3 &

# Disabilita screensaver e risparmio energetico
xset s off
xset -dpms
xset s noblank

# Imposta la risoluzione (opzionale, modificare secondo hardware)
# xrandr --output HDMI-1 --mode 1920x1080

# Imposta il volume audio al 80%
pactl set-sink-volume @DEFAULT_SINK@ 80%

# Avvia OlderOS in fullscreen
cd /opt/olderos
./olderos_launcher &

# Mantieni OlderOS sempre in primo piano
sleep 2
xdotool search --name "OlderOS" windowactivate

# Loop per riavviare OlderOS se si chiude (failsafe)
while true; do
    if ! pgrep -x "olderos_launcher" > /dev/null; then
        echo "OlderOS terminato, riavvio..."
        cd /opt/olderos
        ./olderos_launcher &
        sleep 2
    fi
    sleep 5
done
