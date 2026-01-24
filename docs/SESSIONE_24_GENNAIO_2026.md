# Sessione 24 Gennaio 2026

## Obiettivo della sessione
Test dell'app su Linux e configurazione del Kiosk Mode.

## Progressi completati

### 1. Test su Linux ARM64

**Ambiente di test**: VM Ubuntu 24.04 ARM64 su UTM (Mac Apple Silicon)

**Problema iniziale**: La build GitHub Actions era per x86_64, ma la VM era ARM64.

**Soluzione**: Compilazione diretta nella VM:
```bash
cd ~/OlderOS/launcher
flutter build linux --release
```

**Dipendenze richieste su Linux**:
```bash
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev lld llvm
```

### 2. Fix flusso Setup Wizard ridondante

**Problema**: Il nome utente veniva chiesto due volte:
1. Durante la creazione account (UserSetupScreen)
2. Durante il Setup Wizard (SetupWizardScreen)

**Soluzione**: Modificato `setup_wizard_screen.dart`:
- Rimossa la pagina del nome/avatar dal wizard
- Il wizard ora usa i dati già inseriti durante la creazione account
- Ridotto da 5 a 4 pagine
- Aggiunto saluto personalizzato "Ciao [Nome]!"

**File modificati**:
- `lib/screens/setup_wizard_screen.dart`

### 3. Fix PIN da tastiera su Linux

**Problema**: Il PIN poteva essere inserito solo con il mouse, non dalla tastiera fisica.

**Causa**: Il `KeyboardListener` non riceveva il focus automaticamente su Linux.

**Soluzione**:
- Aggiunto `requestFocus()` esplicito in `initState`
- Aggiunto `requestFocus()` in `onPageChanged` quando si arriva alle pagine PIN

**File modificati**:
- `lib/screens/pin_entry_screen.dart`
- `lib/screens/user_setup_screen.dart`

### 4. Fix logo emoji cross-platform

**Problema**: L'emoji 👴🏻 non veniva visualizzato su Linux (mancava il font emoji).

**Soluzione**:
- Creato widget `OlderOSLogo` riutilizzabile
- Scaricata immagine PNG dell'emoji da Google Noto Emoji
- L'immagine viene inclusa negli assets dell'app

**File creati/modificati**:
- `lib/widgets/olderos_logo.dart` (nuovo)
- `assets/images/elderly_emoji.png` (nuovo)
- `pubspec.yaml` (aggiunta sezione assets)

### 5. Fix CI GitHub Actions

**Problema**: La build falliva per warning di deprecazione.

**Soluzione**: Aggiunto `--no-fatal-warnings` al comando `flutter analyze`.

**File modificato**:
- `.github/workflows/build-linux.yml`

### 6. Configurazione Kiosk Mode

**Primo tentativo - Wayland + Cage**: Non funzionava su VM UTM (schermo nero).

**Soluzione finale - X11 + Openbox**: Funzionante!

**Componenti del Kiosk Mode**:
- **Openbox**: Window manager minimale
- **Auto-login**: Utente `olderos` fa login automatico
- **startx**: Avvia X11 automaticamente da `.bash_profile`
- **unclutter**: Nasconde il cursore dopo 1 secondo di inattività

**File creati**:
| File | Descrizione |
|------|-------------|
| `system/kiosk/setup-kiosk.sh` | Setup Wayland/Cage (non compatibile VM) |
| `system/kiosk/setup-kiosk-x11.sh` | Setup X11/Openbox (funzionante) |
| `system/kiosk/install-app.sh` | Installa app in /opt/olderos |
| `system/kiosk/disable-kiosk.sh` | Disabilita kiosk mode |
| `system/kiosk/README.md` | Documentazione completa |

**Percorso app installata**: `/opt/olderos/`

## Problemi risolti durante la sessione

| Problema | Causa | Soluzione |
|----------|-------|-----------|
| Build x86 su VM ARM | GitHub Actions usa x86_64 | Compilazione locale nella VM |
| Nome chiesto 2 volte | Flusso ridondante | Rimossa pagina dal wizard |
| PIN tastiera non funziona | Focus non assegnato | requestFocus() esplicito |
| Logo non visibile | Manca font emoji | Immagine PNG negli assets |
| CI fallisce | Warning trattati come errori | --no-fatal-warnings |
| Cage non funziona su VM | Incompatibilità virtio-gpu | Usato X11 + Openbox |
| App non trovata in kiosk | File non copiati | Copia manuale via Live USB |

## Stato del progetto

### Funzionalità completate
- Sistema multi-utente (max 4 utenti)
- Autenticazione PIN (4-6 cifre) con hash SHA-256
- Dati separati per ogni utente
- Gestione utenti da Impostazioni
- Cambio utente dalla home
- Migrazione dati legacy
- Blocco dopo 5 tentativi errati
- **Test su Linux ARM64** ✅
- **Kiosk Mode (X11 + Openbox)** ✅

### Roadmap rimanente
1. ~~Test su Linux~~ ✅
2. ~~Configurazione Kiosk mode~~ ✅
3. Rifinitura UI
4. Creazione ISO
5. Test con utenti reali

## Note tecniche

### Configurazione VM UTM consigliata
- **Display**: virtio-gpu-pci
- **RAM**: 4GB minimo
- **Storage**: 20GB minimo
- **CPU**: 2+ core

### Comandi utili per debug kiosk
```bash
# Vedere log del kiosk
journalctl -u olderos-kiosk.service -f

# Accedere a TTY alternativo (da Mac)
Control + Option + F2

# Disabilitare kiosk mode
sudo bash /path/to/disable-kiosk.sh
```

## Prossima sessione
- Rifinitura UI (da definire aspetti specifici)
- Eventuali fix emersi dai test
- Preparazione per creazione ISO
