# OlderOS - Documento di Specifiche MVP

## 1. Vision del Progetto

### 1.1 Missione
Creare un sistema operativo che combatta l'analfabetismo digitale, permettendo agli anziani di utilizzare un computer in modo autonomo e senza frustrazione.

### 1.2 Principi Guida
- **Semplicità radicale**: ogni elemento superfluo è un ostacolo
- **Zero curva di apprendimento**: l'interfaccia deve essere comprensibile al primo sguardo
- **Perdono degli errori**: nessuna azione deve essere irreversibile o spaventosa
- **Consistenza totale**: stesse interazioni, stessi pattern ovunque

### 1.3 Nome del Progetto
**OlderOS** - Un sistema operativo pensato per chi ha più esperienza di vita che di tecnologia.

---

## 2. Target Utente

### 2.1 Profilo Primario
- **Età**: 65-85 anni
- **Esperienza digitale**: minima o nulla
- **Dispositivi posseduti**: probabilmente uno smartphone (usato per chiamate e WhatsApp)
- **Motivazioni**: restare in contatto con famiglia, leggere notizie, gestire piccole attività quotidiane
- **Paure**: "rompere qualcosa", "non capire", "fare brutta figura"

### 2.2 Limitazioni da Considerare
- **Vista**: testi grandi (minimo 18px, ideale 24px), contrasto elevato
- **Motricità fine**: target touch/click grandi (minimo 60x60px), no doppio click, no drag & drop
- **Memoria**: icone sempre visibili, nessun menu nascosto, percorsi brevi
- **Ansia tecnologica**: feedback rassicuranti, nessun messaggio di errore tecnico

### 2.3 Scenari d'Uso Principali
1. Videochiamare nipoti/figli
2. Guardare foto ricevute dalla famiglia
3. Leggere notizie online
4. Scrivere e stampare un documento semplice
5. Inviare/ricevere email

---

## 3. Ambiente di Sviluppo

### 3.1 Setup Macchina di Sviluppo (Mac)

Lo sviluppo avviene su Mac con Claude Code. Poiché OlderOS è basato su Linux, serve un ambiente Linux per compilare e testare. La sincronizzazione tra Mac e VM avviene tramite GitHub.

#### 3.1.1 Installazione VM Ubuntu su Mac

**Per Mac Apple Silicon (M1/M2/M3/M4):**
```bash
# 1. Scarica UTM (gratuito, ottimizzato per ARM)
#    https://mac.getutm.app/

# 2. Scarica Ubuntu 24.04 LTS per ARM64
#    https://ubuntu.com/download/server/arm

# 3. Crea VM in UTM:
#    - RAM: 4GB minimo (8GB consigliato)
#    - Storage: 40GB
#    - CPU: 4 core
```

**Per Mac Intel:**
```bash
# Opzione 1: VirtualBox (gratuito)
#    https://www.virtualbox.org/

# Opzione 2: Parallels (a pagamento, più performante)
#    https://www.parallels.com/

# Scarica Ubuntu 24.04 LTS standard (x86_64)
#    https://ubuntu.com/download/desktop
```

#### 3.1.2 Setup Repository GitHub

Prima di tutto, crea il repository su GitHub:

```bash
# ═══════════════════════════════════════════════════════════════
# SUL MAC - Creazione repository
# ═══════════════════════════════════════════════════════════════

# Crea la cartella del progetto
mkdir -p ~/Sviluppo/OlderOS
cd ~/Sviluppo/OlderOS

# Inizializza Git
git init

# Crea .gitignore per Flutter
cat > .gitignore << 'EOF'
# Flutter/Dart
.dart_tool/
.packages
build/
.flutter-plugins
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/
*.iml

# macOS
.DS_Store

# Build
*.exe
*.dll
*.so
*.dylib
EOF

# Crea README iniziale
echo "# OlderOS" > README.md
echo "Sistema operativo per anziani basato su Ubuntu + Flutter" >> README.md

# Primo commit
git add .
git commit -m "Initial commit"

# Collega a GitHub (crea prima il repo su github.com)
git remote add origin https://github.com/TUOUSERNAME/OlderOS.git
git branch -M main
git push -u origin main
```

#### 3.1.3 Configurazione VM Ubuntu

Dopo l'installazione di Ubuntu nella VM:

```bash
# ═══════════════════════════════════════════════════════════════
# NELLA VM UBUNTU - Setup iniziale (da fare una volta sola)
# ═══════════════════════════════════════════════════════════════

# Aggiorna sistema
sudo apt update && sudo apt upgrade -y

# Installa Git
sudo apt install -y git

# Configura Git con le tue credenziali
git config --global user.name "Tuo Nome"
git config --global user.email "tua@email.com"

# Installa dipendenze Flutter per Linux
sudo apt install -y curl clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev

# Installa Flutter
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verifica installazione
flutter doctor

# Installa Openbox (window manager minimale)
sudo apt install -y openbox

# Installa strumenti utili
sudo apt install -y vim htop net-tools

# ═══════════════════════════════════════════════════════════════
# Clona il repository OlderOS
# ═══════════════════════════════════════════════════════════════

cd ~
git clone https://github.com/TUOUSERNAME/OlderOS.git
cd OlderOS

# Ora hai il progetto nella VM, sincronizzato con GitHub
```

#### 3.1.4 Autenticazione GitHub nella VM

Per poter fare `git pull` senza inserire password ogni volta:

```bash
# Opzione 1: HTTPS con credential helper (più semplice)
git config --global credential.helper store
# Al primo pull ti chiede username e token, poi li ricorda

# Opzione 2: SSH key (più sicuro)
ssh-keygen -t ed25519 -C "tua@email.com"
cat ~/.ssh/id_ed25519.pub
# Copia l'output e aggiungilo su GitHub → Settings → SSH Keys
```

### 3.2 Flusso di Lavoro Sviluppo con GitHub

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           CICLO DI SVILUPPO                             │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────┐                              ┌─────────────────┐
│   MAC + CLAUDE  │                              │    VM UBUNTU    │
│      CODE       │                              │   (sul Mac)     │
│                 │           GitHub             │                 │
│  • Scrivi codice│────push────▶ repo ◀───pull───│  • Compila      │
│  • Refactoring  │            OlderOS           │  • Esegui       │
│  • Debug logico │                              │  • Test visivo  │
│                 │◀─────── feedback ────────────│  • Performance  │
└─────────────────┘                              └─────────────────┘
                                                        │
                                                        │ quando MVP pronto
                                                        ▼
                                                 ┌─────────────────┐
                                                 │   PC FISICO     │
                                                 │   (test reale)  │
                                                 │                 │
                                                 │  • Test anziano │
                                                 │  • Hardware     │
                                                 │    reale        │
                                                 │  • Validazione  │
                                                 └─────────────────┘
```

### 3.3 Comandi Quotidiani

```bash
# ═══════════════════════════════════════════════════════════════
# SUL MAC - Dopo una sessione con Claude Code
# ═══════════════════════════════════════════════════════════════

cd ~/Sviluppo/OlderOS
git add .
git commit -m "Descrizione delle modifiche"
git push

# ═══════════════════════════════════════════════════════════════
# NELLA VM UBUNTU - Sincronizza e testa
# ═══════════════════════════════════════════════════════════════

cd ~/OlderOS

# Comando rapido: pull + esegui (una riga sola)
git pull && cd launcher && flutter run -d linux

# Oppure separatamente:
git pull                    # Scarica le ultime modifiche
cd launcher
flutter run -d linux        # Compila e avvia

# ═══════════════════════════════════════════════════════════════
# COMANDI FLUTTER UTILI
# ═══════════════════════════════════════════════════════════════

# Eseguire con hot reload attivo (per vedere modifiche in tempo reale)
flutter run -d linux

# Build versione release (quando vuoi testare performance reali)
flutter build linux --release

# Il build release si trova in:
# ~/OlderOS/launcher/build/linux/x64/release/bundle/

# ═══════════════════════════════════════════════════════════════
# TEST MODALITÀ KIOSK (simula esperienza utente finale)
# ═══════════════════════════════════════════════════════════════

# Avvia sessione Openbox minimale
startx /usr/bin/openbox-session

# Poi avvia OlderOS a schermo intero
~/OlderOS/launcher/build/linux/x64/release/bundle/launcher --fullscreen
```

### 3.4 Alias Utili (opzionale)

Per velocizzare il flusso, aggiungi questi alias:

```bash
# SUL MAC - Aggiungi a ~/.zshrc
alias olderpush='cd ~/Sviluppo/OlderOS && git add . && git commit -m "update" && git push'

# NELLA VM UBUNTU - Aggiungi a ~/.bashrc  
alias olderrun='cd ~/OlderOS && git pull && cd launcher && flutter run -d linux'
alias olderbuild='cd ~/OlderOS/launcher && flutter build linux --release'

# Dopo aver aggiunto, ricarica:
# Mac: source ~/.zshrc
# Ubuntu: source ~/.bashrc

# Ora basta scrivere:
# Mac:    olderpush
# Ubuntu: olderrun
```

### 3.5 Struttura Progetto

```
# Su GitHub: github.com/TUOUSERNAME/OlderOS

OlderOS/                          # Repository GitHub
├── launcher/                     # Progetto Flutter
│   ├── lib/
│   ├── linux/
│   ├── pubspec.yaml
│   └── ...
├── system/                       # Config sistema Linux
├── docs/                         # Documentazione
│   └── OlderOS-MVP-Specifiche.md
├── .gitignore
└── README.md

# Clone locale su Mac:    ~/Sviluppo/OlderOS/
# Clone locale su VM:     ~/OlderOS/
```

### 3.6 Testing

#### Livello 1: Test Tecnico (VM)
- Verifica che compili senza errori
- Verifica che l'UI si visualizzi correttamente
- Testa tutti i flussi di navigazione
- Simula condizioni di errore (no internet, ecc.)

#### Livello 2: Test Utente (PC Fisico)
- Procurati un PC usato economico (anche 100-150€)
- Installa Ubuntu 24.04 + OlderOS
- Fai provare a un anziano reale
- Osserva senza intervenire, prendi appunti

#### Livello 3: Test Distribuzione (ISO)
- Crea immagine ISO personalizzata
- Testa installazione da zero su PC pulito
- Verifica che tutto funzioni al primo avvio

---

## 4. Architettura Tecnica

### 4.1 Sistema Base
- **Distribuzione**: Ubuntu 24.04 LTS (supporto fino ad Aprile 2029)
- **Installazione**: immagine ISO personalizzata con autoconfigurazione
- **Requisiti hardware minimi**: CPU dual-core, 4GB RAM, 32GB storage, scheda video integrata

### 4.2 Stack Software
```
┌─────────────────────────────────────────┐
│          OlderOS Launcher               │  ← Flutter App (interfaccia utente)
├─────────────────────────────────────────┤
│              Openbox WM                 │  ← Window Manager minimale
├─────────────────────────────────────────┤
│           X11 / Wayland                 │  ← Display Server
├─────────────────────────────────────────┤
│           Ubuntu 24.04 LTS              │  ← Sistema operativo base
└─────────────────────────────────────────┘
```

### 4.3 Tecnologie per le Applicazioni
- **Launcher principale**: Flutter for Linux
- **Browser**: Firefox in modalità kiosk (configurazione custom)
- **Email**: Client custom Flutter o Geary semplificato
- **Videochiamate**: integrazione con servizio web-based (Jitsi Meet)
- **Scrittura**: LibreOffice Writer in modalità semplificata o editor custom
- **Foto**: Visualizzatore custom Flutter

### 4.4 Configurazione Sistema
- Avvio automatico del Launcher (no login screen visibile)
- Nessun accesso al terminale per l'utente
- Nessun file manager tradizionale
- Aggiornamenti automatici silenziosi
- Spegnimento/riavvio solo da interfaccia OlderOS

---

## 5. Interfaccia Utente MVP

### 5.1 Schermata Home (Launcher)

```
┌────────────────────────────────────────────────────────────────┐
│                                                                │
│     Buongiorno, Mario!                    Lunedì 3 Gennaio     │
│     ══════════════════                    ore 10:30            │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │              │  │              │  │              │         │
│  │   🌐         │  │   ✉️         │  │   📝         │         │
│  │              │  │              │  │              │         │
│  │  INTERNET    │  │   POSTA      │  │  SCRIVERE    │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │              │  │              │  │              │         │
│  │   📷         │  │   📹         │  │   ⚙️         │         │
│  │              │  │              │  │              │         │
│  │    FOTO      │  │ VIDEOCHIAMATA│  │  IMPOSTAZIONI│         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│                                                                │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │                    SPEGNI COMPUTER                      │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

#### Specifiche elementi Home:
- **Sfondo**: colore solido, tenue (azzurro chiaro o grigio caldo)
- **Saluto**: personalizzato con nome utente + data/ora ben visibili
- **Icone applicazioni**: 200x200px minimo, con label sempre visibile sotto
- **Icone**: flat design, colori distintivi per ogni app, no gradienti complessi
- **Pulsante spegnimento**: sempre visibile, posizione fissa in basso

### 5.2 Navigazione Globale

Ogni applicazione ha una barra superiore fissa:

```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                              [Nome App]       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│                    [Contenuto applicazione]                    │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- **"Torna a Casa"**: sempre visibile, sempre stesso posto, sempre stessa dicitura
- **Nessun pulsante "indietro"** nelle app: si torna solo alla Home
- **Nessuna "X" per chiudere**: solo "Torna a Casa"

### 5.3 App: Internet (Browser)

#### Schermata iniziale browser:
```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                              INTERNET         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│     Cosa vuoi cercare?                                         │
│     ┌────────────────────────────────────────────────────┐    │
│     │                                                    │ 🔍 │
│     └────────────────────────────────────────────────────┘    │
│                                                                │
│     Siti preferiti:                                            │
│     ┌─────────────┐ ┌─────────────┐ ┌─────────────┐           │
│     │ Repubblica  │ │  RAI News   │ │   Meteo     │           │
│     └─────────────┘ └─────────────┘ └─────────────┘           │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- Barra di ricerca grande e centrale (usa Google)
- Siti preferiti preconfigurati + personalizzabili da admin/famiglia
- Durante navigazione: solo pulsanti "Indietro pagina", "Torna a inizio", "Torna a Casa"
- Nessuna barra degli indirizzi visibile
- Nessun sistema di tab

### 5.4 App: Posta (Email)

#### Schermata principale:
```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                                POSTA          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │              ✏️ SCRIVI NUOVO MESSAGGIO                  │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
│  Messaggi ricevuti:                                            │
│  ┌────────────────────────────────────────────────────────┐   │
│  │ 👤 Maria (figlia)                         Oggi, 09:15  │   │
│  │ Ciao papà, ti mando le foto...                         │   │
│  └────────────────────────────────────────────────────────┘   │
│  ┌────────────────────────────────────────────────────────┐   │
│  │ 👤 Farmacia San Marco                      Ieri        │   │
│  │ Le ricordiamo che la sua ricetta...                    │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- Un solo account email (configurato al setup)
- Solo "Ricevuti" e "Inviati" - nessuna cartella
- Mittenti mostrati con nome (mai email), con foto se nei contatti
- Eliminazione con conferma gentile: "Sei sicuro di voler eliminare questo messaggio?"

### 5.5 App: Scrivere (Elaboratore testi)

```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA          💾 SALVA          🖨️ STAMPA         │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│     Documento senza titolo                                     │
│     ─────────────────────────────────────────────────────     │
│                                                                │
│     |                                                          │
│                                                                │
│                                                                │
│                                                                │
│                                                                │
│                                                                │
│                                                                │
├────────────────────────────────────────────────────────────────┤
│  [A-] [A+]    [G] [C] [S]    [≡] [≡] [≡]                      │
│  Testo       Grassetto      Allinea                            │
│  più piccolo Corsivo        sinistra                           │
│  più grande  Sottolineato   centro destra                      │
└────────────────────────────────────────────────────────────────┘
```

- Formattazione essenziale: dimensione testo, grassetto/corsivo/sottolineato, allineamento
- Salvataggio automatico continuo (+ pulsante salva per rassicurazione)
- Stampa con anteprima semplice
- Documenti salvati accessibili da una lista "I miei documenti"

### 5.6 App: Foto

```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                                 FOTO          │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│  │      │ │      │ │      │ │      │ │      │ │      │       │
│  │ img1 │ │ img2 │ │ img3 │ │ img4 │ │ img5 │ │ img6 │       │
│  │      │ │      │ │      │ │      │ │      │ │      │       │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘       │
│                                                                │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐       │
│  │      │ │      │ │      │ │      │ │      │ │      │       │
│  │ img7 │ │ img8 │ │ img9 │ │img10 │ │img11 │ │img12 │       │
│  │      │ │      │ │      │ │      │ │      │ │      │       │
│  └──────┘ └──────┘ └──────┘ └──────┘ └──────┘ └──────┘       │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- Griglia semplice di foto
- Click per aprire a schermo intero con frecce avanti/indietro
- Le foto arrivano da: email (salvate automaticamente), chiavetta USB (rilevata automaticamente)
- Nessuna organizzazione in album (MVP)

### 5.7 App: Videochiamata

```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                           VIDEOCHIAMATA       │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│     Chi vuoi chiamare?                                         │
│                                                                │
│     ┌─────────────────────┐  ┌─────────────────────┐          │
│     │         👩          │  │         👨          │          │
│     │                     │  │                     │          │
│     │       Maria         │  │       Luca          │          │
│     │      (figlia)       │  │      (figlio)       │          │
│     │                     │  │                     │          │
│     │   📹 CHIAMA         │  │   📹 CHIAMA         │          │
│     └─────────────────────┘  └─────────────────────┘          │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- Contatti preconfigurati con foto grandi
- Click su "Chiama" → parte videochiamata a schermo intero
- Durante chiamata: solo pulsanti "TERMINA" (rosso, grande) e "Microfono on/off"
- Backend: Jitsi Meet (open source, nessun account richiesto)

### 5.8 App: Impostazioni

```
┌────────────────────────────────────────────────────────────────┐
│  🏠 TORNA A CASA                           IMPOSTAZIONI        │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  🔆 LUMINOSITÀ SCHERMO                          [===] │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  🔊 VOLUME SUONI                                [===] │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  🌐 RETE WIFI: Casa_Mario                    ✓ Connesso│   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  🖨️ STAMPANTE: HP DeskJet                   ✓ Pronta  │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
│  ┌────────────────────────────────────────────────────────┐   │
│  │  ℹ️ CHIEDI AIUTO A DISTANZA                            │   │
│  └────────────────────────────────────────────────────────┘   │
│                                                                │
└────────────────────────────────────────────────────────────────┘
```

- Solo impostazioni essenziali
- WiFi: lista reti, click per connettersi, tastiera per password
- "Chiedi aiuto a distanza": attiva condivisione schermo per supporto familiare (fase 2)

---

## 6. Design System

### 6.1 Palette Colori
```
Sfondo principale:     #F5F5F5 (grigio chiarissimo)
Sfondo cards:          #FFFFFF (bianco)
Testo principale:      #1A1A1A (nero quasi puro)
Testo secondario:      #666666 (grigio scuro)
Colore primario:       #2563EB (blu accessibile)
Colore successo:       #16A34A (verde)
Colore pericolo:       #DC2626 (rosso)
Colore attenzione:     #F59E0B (arancione)
```

### 6.2 Tipografia
```
Font principale:       Inter (o Roboto come fallback)
Dimensione base:       24px
Titoli sezione:        32px, bold
Titoli app:            28px, semibold
Testo bottoni:         22px, medium
Testo secondario:      20px, regular
```

### 6.3 Spaziature
```
Padding cards:         24px
Gap tra elementi:      20px
Margini schermo:       32px
Border radius cards:   16px
```

### 6.4 Feedback Interattivi
- **Hover/Focus**: bordo colorato + leggero ingrandimento (1.02x)
- **Click**: effetto "press" (scala 0.98x)
- **Caricamento**: spinner semplice + testo "Attendi..."
- **Successo**: animazione check verde + testo conferma
- **Errore**: mai messaggi tecnici, sempre spiegazioni umane

### 6.5 Icone
- Set: Material Icons o Phosphor Icons
- Stile: outline o filled (consistente in tutta l'app)
- Dimensione: minimo 48x48px, ideale 64x64px nelle cards

---

## 7. Flussi Utente Critici

### 7.1 Primo Avvio (Setup Wizard)
```
Schermata 1: "Benvenuto! Come ti chiami?"
             [Campo nome] → Avanti

Schermata 2: "Connettiamoci a Internet"
             [Lista reti WiFi] → Seleziona → Password → Avanti

Schermata 3: "Configuriamo la tua posta"
             [Email] [Password] → Avanti
             (oppure "Lo faccio dopo")

Schermata 4: "Tutto pronto!"
             [Inizia a usare OlderOS]
```

### 7.2 Spegnimento Computer
```
Click "SPEGNI COMPUTER"
    ↓
Popup: "Vuoi spegnere il computer?"
       [Sì, spegni] [No, torna indietro]
    ↓
Se sì: "Il computer si sta spegnendo... Buona giornata, Mario!"
       (spegnimento dopo 3 secondi)
```

### 7.3 Errore Connessione Internet
```
Utente apre "Internet"
    ↓
Sistema rileva no connessione
    ↓
Schermata: "Non riesco a collegarmi a Internet"
           "Prova a verificare che il modem sia acceso"
           [🔄 Riprova] [🏠 Torna a Casa]
```

---

## 8. Architettura Codebase

### 8.1 Struttura Directory
```
olderos/
├── launcher/                    # App Flutter principale
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── browser_screen.dart
│   │   │   ├── email_screen.dart
│   │   │   ├── writer_screen.dart
│   │   │   ├── photos_screen.dart
│   │   │   ├── videocall_screen.dart
│   │   │   └── settings_screen.dart
│   │   ├── widgets/
│   │   │   ├── app_card.dart
│   │   │   ├── top_bar.dart
│   │   │   ├── big_button.dart
│   │   │   └── ...
│   │   ├── services/
│   │   │   ├── email_service.dart
│   │   │   ├── storage_service.dart
│   │   │   └── ...
│   │   └── theme/
│   │       └── olderos_theme.dart
│   └── pubspec.yaml
├── system/                      # Configurazioni sistema
│   ├── openbox/
│   │   └── rc.xml              # Config Openbox
│   ├── autostart/
│   │   └── olderos.desktop     # Avvio automatico
│   └── scripts/
│       ├── setup.sh            # Script installazione
│       └── update.sh           # Script aggiornamenti
├── iso/                         # Build immagine ISO
│   └── build-iso.sh
└── docs/
    └── README.md
```

### 8.2 Dipendenze Principali Flutter
```yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.0.0      # Per browser integrato
  flutter_email_sender: ^6.0.0  # Per email
  url_launcher: ^6.0.0          # Per link esterni
  shared_preferences: ^2.0.0    # Per storage locale
  provider: ^6.0.0              # State management
  google_fonts: ^6.0.0          # Typography
```

---

## 9. Roadmap Sviluppo MVP

### Fase 0: Setup Ambiente Mac + GitHub (1 giorno)
- [ ] Creare repository GitHub "OlderOS"
- [ ] Clonare repository sul Mac in ~/Sviluppo/OlderOS
- [ ] Installare UTM (Apple Silicon) o VirtualBox (Intel)
- [ ] Creare VM Ubuntu 24.04 LTS
- [ ] Configurare Flutter nella VM
- [ ] Clonare repository nella VM
- [ ] Configurare autenticazione GitHub nella VM
- [ ] Verificare che `flutter doctor` sia tutto verde
- [ ] Testare ciclo push (Mac) → pull (VM)

### Fase 1: Setup Ambiente Linux (1-2 giorni)
- [ ] Configurare Openbox come window manager
- [ ] Creare script di avvio automatico launcher
- [ ] Testare avvio in modalità kiosk

### Fase 2: Launcher Base (3-5 giorni)
- [ ] Schermata Home con 6 cards
- [ ] Navigazione base (TopBar + "Torna a Casa")
- [ ] Design system implementato (colori, font, spacing)
- [ ] Pulsante spegnimento funzionante

### Fase 3: App Internet (3-4 giorni)
- [ ] WebView integrata
- [ ] Pagina iniziale con ricerca
- [ ] Gestione siti preferiti
- [ ] Pulsanti navigazione semplificati

### Fase 4: App Posta (4-5 giorni)
- [ ] Configurazione account (IMAP/SMTP)
- [ ] Lista messaggi ricevuti
- [ ] Visualizzazione singolo messaggio
- [ ] Composizione nuovo messaggio
- [ ] Invio email

### Fase 5: App Scrivere (3-4 giorni)
- [ ] Editor testo base
- [ ] Formattazione essenziale
- [ ] Salvataggio/caricamento documenti
- [ ] Funzione stampa

### Fase 6: App Foto (2-3 giorni)
- [ ] Griglia foto
- [ ] Visualizzatore fullscreen
- [ ] Importazione da cartella

### Fase 7: App Videochiamata (3-4 giorni)
- [ ] Integrazione Jitsi Meet
- [ ] Lista contatti
- [ ] Avvio/termine chiamata

### Fase 8: Testing e Rifinitura (3-5 giorni)
- [ ] Test con utenti reali (anziani)
- [ ] Bug fixing
- [ ] Ottimizzazione performance
- [ ] Creazione immagine ISO installabile

**Tempo totale stimato: 25-35 giorni di sviluppo**

---

## 10. Note per Claude Code

### 10.1 Approccio Consigliato
1. Iniziare dalla struttura del progetto Flutter
2. Implementare prima il launcher e la navigazione
3. Aggiungere una app alla volta, partendo da Internet
4. Testare frequentemente su VM Ubuntu
5. Mantenere il codice semplice e ben commentato

### 10.2 Priorità di Sviluppo
**Essenziale per MVP**: Home, Internet, Posta, Spegnimento
**Importante**: Scrivere, Foto
**Opzionale per MVP**: Videochiamata, Impostazioni avanzate

### 10.3 Comandi Utili nella VM
```bash
# Setup Flutter Linux (già fatto nel setup iniziale)
sudo apt update
sudo apt install flutter clang cmake ninja-build pkg-config libgtk-3-dev

# Creare progetto
flutter create --platforms=linux olderos_launcher

# Eseguire
cd olderos_launcher
flutter run -d linux

# Build release
flutter build linux --release
```

### 10.4 Testing
- Usare VM Ubuntu sul Mac per test quotidiani
- Testare con risoluzione 1920x1080 (più comune)
- Simulare hardware limitato (4GB RAM, CPU limitata)
- Test finale su PC fisico con anziano reale

---

## 11. Distribuzione Finale

### 11.1 Creazione ISO Personalizzata

Quando l'MVP è pronto, creerai un'immagine ISO installabile:

```bash
# Strumenti per creare ISO custom Ubuntu
sudo apt install cubic

# Cubic permette di:
# - Partire da ISO Ubuntu ufficiale
# - Aggiungere OlderOS preinstallato
# - Configurare avvio automatico
# - Rimuovere software non necessario
# - Generare nuova ISO
```

### 11.2 Modalità di Distribuzione

1. **Download ISO** → L'utente (o un familiare) scarica, crea chiavetta USB, installa
2. **PC Preconfigurato** → Tu installi su PC usati e li distribuisci
3. **Servizio installazione** → Offri installazione a domicilio

---

## 12. Metriche di Successo MVP

Il MVP è considerato riuscito se:
1. Un anziano riesce ad accendere il PC e navigare su Google **senza aiuto**
2. Un anziano riesce a leggere e rispondere a un'email **senza aiuto**
3. Il tempo per completare ogni task è **inferiore a 2 minuti**
4. L'anziano **non esprime frustrazione** durante l'uso
5. L'anziano **chiede di riusare** il sistema

---

*Documento creato: Gennaio 2026*
*Versione: 1.1*
*Autore: Matteo + Claude*
*Nome progetto: OlderOS*
