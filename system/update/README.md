# OlderOS - Sistema di Aggiornamento

Script per aggiornare OlderOS quando è in esecuzione in Kiosk Mode.

## Problema

Quando il Kiosk Mode è attivo, OlderOS parte automaticamente senza accesso al terminale.

## Soluzione

### 1. Accedi al TTY alternativo

Dalla VM UTM su Mac:
```
Control + Option + F2
```

Questo apre un terminale testuale. Fai login con l'utente `olderos`.

### 2. Aggiorna OlderOS

```bash
~/OlderOS/system/update/update-olderos.sh
```

Lo script:
- Scarica le ultime modifiche da GitHub
- Compila l'app
- Installa in `/opt/olderos`
- Chiede se riavviare

### 3. Torna all'interfaccia grafica

```
Control + Option + F1
```

Oppure riavvia se hai aggiornato.

---

## Modalità Manutenzione

Se hai bisogno di fare manutenzione più approfondita:

```bash
# Entra in modalità manutenzione (terminale al riavvio)
~/OlderOS/system/update/maintenance-mode.sh on
sudo reboot

# Dopo aver finito, torna al Kiosk Mode
~/OlderOS/system/update/maintenance-mode.sh off
sudo reboot
```

---

## Prima installazione degli script

Dopo aver clonato il repo, rendi eseguibili gli script:

```bash
chmod +x ~/OlderOS/system/update/*.sh
```

---

## Comandi rapidi

| Azione | Comando |
|--------|---------|
| Aggiorna OlderOS | `~/OlderOS/system/update/update-olderos.sh` |
| Entra in manutenzione | `~/OlderOS/system/update/maintenance-mode.sh on` |
| Esci da manutenzione | `~/OlderOS/system/update/maintenance-mode.sh off` |
| Verifica stato | `~/OlderOS/system/update/maintenance-mode.sh status` |
| Vai a TTY2 | `Ctrl+Alt+F2` (o `Ctrl+Opt+F2` su Mac) |
| Torna a GUI | `Ctrl+Alt+F1` (o `Ctrl+Opt+F1` su Mac) |
