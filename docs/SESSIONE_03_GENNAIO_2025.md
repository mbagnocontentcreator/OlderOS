# Sessione di Sviluppo - 3 Gennaio 2025

## Riepilogo

In questa sessione abbiamo completato l'MVP del Launcher OlderOS, un sistema operativo semplificato per anziani basato su Ubuntu + Flutter.

---

## Fase 0: Setup Iniziale

### Repository e Struttura
- Inizializzato repository Git
- Creato progetto Flutter: `flutter create --platforms=linux,macos --project-name=olderos_launcher launcher`
- Creato repository GitHub: https://github.com/mbagnocontentcreator/OlderOS
- Struttura directory: `launcher/`, `system/`, `docs/`

### Dipendenze Installate
- Flutter 3.38.5 (via Homebrew)
- CocoaPods (per macOS)
- GitHub CLI

### Problemi Risolti
1. **CardTheme vs CardThemeData**: Flutter 3.x richiede `CardThemeData`
2. **Google Fonts network error**: Sandbox macOS bloccava download font - rimosso google_fonts, usato font di sistema
3. **CocoaPods mancante**: Installato via `brew install cocoapods`

---

## Fase 1-2: Launcher Base

### Theme System (`lib/theme/olderos_theme.dart`)
- Colori: primary (#2563EB), danger (#DC2626), success (#16A34A), warning (#F59E0B)
- Font size: 24px+ per accessibilita
- Card size: 200x200px, icon size: 64px
- Touch target minimo: 60x60px

### Widget Riutilizzabili
- `AppCard` - Card per le app con hover/press animation
- `TopBar` - Barra navigazione con "TORNA A CASA"
- `BigButton` - Pulsante grande per azioni importanti

### HomeScreen
- Saluto personalizzato con data/ora in italiano
- Griglia 6 app cards
- Pulsante spegnimento con dialog conferma

---

## Fase 3: App Implementate

### 1. Internet (`browser_screen.dart`, `webview_screen.dart`)
- Barra di ricerca Google
- 6 siti preferiti: Repubblica, RAI News, Meteo, Google, YouTube, Wikipedia
- WebView con navigazione semplificata (Home, Indietro, Ricarica)
- Indicatore caricamento

### 2. Foto (`photos_screen.dart`, `photo_viewer_screen.dart`)
- Griglia 4 colonne con 12 foto sample (picsum.photos)
- Visualizzatore fullscreen con frecce navigazione
- Supporto tastiera (frecce, ESC)
- Indicatore pagina con pallini

### 3. Scrivere (`writer_screen.dart`)
- Lista documenti salvati
- Editor testo con toolbar formattazione:
  - Grassetto, Corsivo, Sottolineato
  - Dimensione testo (Piccolo/Normale/Grande)
  - Allineamento (Sinistra/Centro/Destra)
- Salvataggio con conferma
- Avviso modifiche non salvate

### 4. Impostazioni (`settings_screen.dart`)
- Slider luminosita schermo
- Slider volume
- Selettore rete WiFi
- Sezione stampante
- Info sistema

### 5. Posta (`email_screen.dart`, `email_view_screen.dart`, `compose_email_screen.dart`)
- Tab Ricevuti/Inviati con badge non letti
- Lista email con avatar, anteprima, data
- Visualizzazione email completa
- Composizione con:
  - Selettore contatti dropdown
  - Campi A/Oggetto/Corpo
  - Validazione prima invio
- Conferma eliminazione

### 6. Videochiamata (`videocall_screen.dart`)
- 4 contatti familiari con avatar colorati:
  - Maria (figlia), Luca (figlio), Anna (nipote), Paolo (fratello)
- Card contatto con pulsante "CHIAMA"
- Dialog conferma chiamata
- Integrazione Jitsi Meet via url_launcher
- Schermata connessione con progress indicator

---

## Commit History

```
910d014 Add Videocall app with Jitsi Meet integration
41abf47 Add Email (Posta) app
a4509ea Add Settings app
c51da8a Add Writer (text editor) app
47895fc Add Photos app
0884887 Add Internet browser app
f8a1234 Add launcher base structure with theme and widgets
```

---

## File Structure

```
OlderOS/
├── docs/
│   ├── OlderOS-MVP-Specifiche.md
│   └── SESSIONE_03_GENNAIO_2025.md
├── launcher/
│   ├── lib/
│   │   ├── main.dart
│   │   ├── theme/
│   │   │   └── olderos_theme.dart
│   │   ├── widgets/
│   │   │   ├── app_card.dart
│   │   │   ├── top_bar.dart
│   │   │   └── big_button.dart
│   │   └── screens/
│   │       ├── home_screen.dart
│   │       ├── app_screen.dart
│   │       ├── browser_screen.dart
│   │       ├── webview_screen.dart
│   │       ├── photos_screen.dart
│   │       ├── photo_viewer_screen.dart
│   │       ├── writer_screen.dart
│   │       ├── settings_screen.dart
│   │       ├── email_screen.dart
│   │       ├── email_view_screen.dart
│   │       ├── compose_email_screen.dart
│   │       └── videocall_screen.dart
│   ├── macos/
│   ├── linux/
│   └── pubspec.yaml
├── system/
├── .gitignore
└── README.md
```

---

## Dipendenze Flutter (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  intl: ^0.19.0
  webview_flutter: ^4.10.0
  webview_flutter_wkwebview: ^3.16.3
  url_launcher: ^6.3.1
```

---

## Test Linux Completato

**OlderOS testato con successo su Ubuntu 24.04 ARM64 in VM UTM**

- Tutte le 6 app funzionanti
- Interfaccia responsive
- Navigazione fluida

---

## Prossimi Passi

1. ~~**Test su Linux/Ubuntu** - Verificare funzionamento su target OS~~ FATTO
2. **Persistenza dati** - Salvare documenti, email, impostazioni
3. **Foto reali** - Accesso a cartella foto utente
4. **Email reale** - Integrazione IMAP/SMTP
5. **Accessibilita** - Screen reader, navigazione tastiera completa
6. **Installer** - Pacchetto .deb per Ubuntu

---

## CI/CD - GitHub Actions

### Workflow Linux Build (`.github/workflows/build-linux.yml`)
- Trigger: push/PR su main
- Runner: ubuntu-latest
- Steps:
  1. Install Linux dependencies (clang, cmake, GTK3, etc.)
  2. Setup Flutter (stable channel, cached)
  3. flutter pub get
  4. flutter analyze
  5. flutter build linux --release
  6. Upload artifact (retention 7 giorni)

### Artifact
- Nome: `olderos-launcher-linux`
- Contenuto: bundle completo eseguibile
- Download: https://github.com/mbagnocontentcreator/OlderOS/actions

---

## Test Environment - UTM + Ubuntu

### Configurazione VM
- **Virtualizzatore**: UTM 4.7.5
- **OS Guest**: Ubuntu 22.04 Desktop ARM64
- **RAM**: 4-8 GB
- **CPU**: 2-4 cores
- **Storage**: 25+ GB

### Setup Flutter in Ubuntu VM
```bash
# Dipendenze
sudo apt install -y git curl clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev

# Flutter
git clone https://github.com/flutter/flutter.git ~/flutter
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# OlderOS
git clone https://github.com/mbagnocontentcreator/OlderOS.git
cd OlderOS/launcher
flutter pub get
flutter run -d linux
```

---

## Note Tecniche

- **Piattaforma sviluppo**: macOS (Darwin 25.1.0) - Apple Silicon
- **Flutter version**: 3.38.5
- **Target platforms**: Linux, macOS
- **Repository**: https://github.com/mbagnocontentcreator/OlderOS
- **CI/CD**: GitHub Actions (Linux build automatico)
