# OlderOS

Sistema operativo per anziani basato su Ubuntu + Flutter.

## Missione

Creare un sistema operativo che combatta l'analfabetismo digitale, permettendo agli anziani di utilizzare un computer in modo autonomo e senza frustrazione.

## Principi Guida

- **Semplicita radicale**: ogni elemento superfluo e un ostacolo
- **Zero curva di apprendimento**: l'interfaccia deve essere comprensibile al primo sguardo
- **Perdono degli errori**: nessuna azione deve essere irreversibile o spaventosa
- **Consistenza totale**: stesse interazioni, stessi pattern ovunque

## Stack Tecnico

- **Sistema base**: Ubuntu 24.04 LTS
- **Window Manager**: Openbox
- **Interfaccia utente**: Flutter for Linux
- **Display Server**: X11

## Struttura Progetto

```
OlderOS/
├── launcher/          # App Flutter principale (interfaccia utente)
├── system/            # Configurazioni sistema Linux
├── docs/              # Documentazione
└── README.md
```

## Setup Sviluppo

### Requisiti Mac

- Git
- Flutter SDK
- UTM (Apple Silicon) o VirtualBox (Intel) per VM Ubuntu

### Requisiti VM Ubuntu

- Ubuntu 24.04 LTS
- Flutter SDK
- Openbox

### Flusso di Lavoro

1. Sviluppa codice sul Mac con Claude Code
2. Push su GitHub
3. Pull nella VM Ubuntu
4. Compila e testa con `flutter run -d linux`

## Comandi Utili

```bash
# Mac - Push modifiche
git add . && git commit -m "descrizione" && git push

# VM Ubuntu - Pull e esegui
git pull && cd launcher && flutter run -d linux

# VM Ubuntu - Build release
cd launcher && flutter build linux --release
```

## Documentazione

Vedi [docs/OlderOS-MVP-Specifiche.md](docs/OlderOS-MVP-Specifiche.md) per le specifiche complete del progetto.

## Licenza

MIT License
