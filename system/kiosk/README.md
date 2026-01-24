# OlderOS Kiosk Mode

Configurazione per avviare OlderOS come sistema operativo dedicato.

## Requisiti

- Ubuntu 22.04+ o Debian 12+ (ARM64 o x86_64)
- Almeno 2GB RAM
- 4GB spazio disco

## Installazione Rapida

### 1. Prepara il sistema

```bash
# Clona il repository
git clone https://github.com/mbagnocontentcreator/OlderOS.git
cd OlderOS

# Esegui setup kiosk
sudo bash system/kiosk/setup-kiosk.sh
```

### 2. Compila e installa l'app

```bash
# Compila (se non hai il bundle pre-compilato)
cd launcher
flutter build linux --release

# Installa l'app
sudo bash ../system/kiosk/install-app.sh build/linux/*/release/bundle
```

### 3. Riavvia

```bash
sudo reboot
```

OlderOS partirà automaticamente!

## Come funziona

Il kiosk mode usa:

- **Cage**: Compositor Wayland minimale per kiosk
- **systemd**: Gestione avvio automatico
- **Auto-login**: L'utente `olderos` fa login automatico

### Struttura servizio

```
/etc/systemd/system/olderos-kiosk.service  # Servizio systemd
/opt/olderos/                               # App installata
/etc/systemd/system/getty@tty1.service.d/   # Auto-login config
```

## Comandi utili

### Controllare lo stato

```bash
sudo systemctl status olderos-kiosk.service
```

### Vedere i log

```bash
sudo journalctl -u olderos-kiosk.service -f
```

### Riavviare l'app

```bash
sudo systemctl restart olderos-kiosk.service
```

### Disabilitare kiosk mode

```bash
sudo bash /path/to/disable-kiosk.sh
```

## Accesso di emergenza

Se hai bisogno di accedere al sistema durante il kiosk mode:

1. **SSH**: Connettiti via SSH da un altro computer
   ```bash
   ssh olderos@<ip-address>
   ```

2. **TTY alternativo**: Premi `Ctrl+Alt+F2` per un terminale alternativo

3. **Recovery mode**: Riavvia in recovery mode dal bootloader

## Personalizzazione

### Cambiare utente kiosk

Modifica la variabile prima di eseguire setup:

```bash
export OLDEROS_USER=mionome
sudo bash setup-kiosk.sh
```

### Cambiare percorso app

```bash
export OLDEROS_APP_PATH=/home/utente/olderos
sudo bash setup-kiosk.sh
```

## Risoluzione problemi

### Schermo nero all'avvio

1. Controlla i log: `sudo journalctl -u olderos-kiosk.service`
2. Verifica che l'app esista: `ls -la /opt/olderos/`
3. Prova ad avviare manualmente: `cage -- /opt/olderos/olderos_launcher`

### App non parte

1. Verifica dipendenze: `ldd /opt/olderos/olderos_launcher`
2. Installa dipendenze mancanti: `sudo apt-get install libgtk-3-0`

### Tastiera/mouse non funzionano

1. Aggiungi l'utente al gruppo input: `sudo usermod -aG input olderos`
2. Riavvia: `sudo reboot`
